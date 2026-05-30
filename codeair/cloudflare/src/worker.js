/**
 * CodeAir FCM Push Worker (Cloudflare Workers)
 * ------------------------------------------------------------
 * IoT 기기가 Firebase에 센서값을 쓴 직후 이 Worker를 HTTP POST로 호출하면,
 *   1) Firebase에서 임계값(config/thresholds) 읽기
 *   2) 전달받은(또는 sensors/latest의) 센서값과 비교
 *   3) 초과 시 Firebase의 FCM 토큰(fcm_tokens) 전체에 푸시 발송
 *   4) 쿨다운(alert_state)으로 중복 알림 방지
 *
 * 인증: Firebase 서비스 계정(JSON)을 Cloudflare Secret으로 주입.
 *   - FB_PROJECT_ID
 *   - FB_CLIENT_EMAIL
 *   - FB_PRIVATE_KEY           (PEM, \n 줄바꿈 포함)
 *   - FB_DATABASE_URL          (예: https://codeair-598fd-default-rtdb.asia-southeast1.firebasedatabase.app)
 *   - SHARED_SECRET (선택)     (IoT 호출 인증용 임의 문자열)
 */

const SCOPES = [
  'https://www.googleapis.com/auth/firebase.messaging',
  'https://www.googleapis.com/auth/firebase.database',
  'https://www.googleapis.com/auth/datastore', // Firestore 경보 기록용
  'https://www.googleapis.com/auth/userinfo.email',
].join(' ');

const REPEAT_MS = 5 * 60 * 1000; // 첫 알람 후 5분마다 반복 (지속 시)

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return json({ error: 'POST only' }, 405);
    }

    // (선택) 공유 비밀로 호출 인증
    if (env.SHARED_SECRET) {
      const auth = request.headers.get('x-codeair-secret');
      if (auth !== env.SHARED_SECRET) {
        return json({ error: 'unauthorized' }, 401);
      }
    }

    let body = {};
    try {
      body = await request.json();
    } catch (_) {
      // body 없이 호출되면 sensors/latest를 읽어 사용
    }

    const deviceId = body.deviceId || 'device_001';

    try {
      const accessToken = await getAccessToken(env);

      // 센서값: body 우선, 없으면 Firebase에서 읽기
      let data = body.data;
      if (!data) {
        data = await rtdbGet(env, accessToken, 'sensors/latest');
      }
      if (!data) return json({ error: 'no sensor data' }, 400);

      // 임계값 읽기 (없으면 기본값) — Flutter AlertService 상수와 일치
      const thr = (await rtdbGet(env, accessToken, 'config/thresholds')) || {};
      const pm25Thr = num(thr.pm25, 35);
      const pm10Thr = num(thr.pm10, 80);
      const co2WarnThr = num(thr.co2Warn, 1000);
      const co2DangerThr = num(thr.co2Danger, 2000);
      const tHigh = 33, tLow = 0, hHigh = 60, hLow = 40;

      // 센서값 추출
      const pm25 = num(data.pm25);
      const pm10 = num(data.pm10);
      const co2 = num(data.co2_ppm ?? data.co2);
      const temp = num(data.temperature);
      const hum = num(data.humidity);

      // ── 초과 항목 판정 ──
      // 각 항목: key(상태), type/severity/value/message(Firestore 경보), title/body(FCM 푸시)
      // 메시지는 Flutter 인앱 표시 형식과 동일하게 유지
      const alerts = [];
      if (pm25 >= pm25Thr) {
        alerts.push({
          key: 'pm25', type: 'pm25', severity: 'warning', value: pm25,
          message: `초미세먼지(PM2.5) 기준 초과: ${pm25.toFixed(1)} µg/m³ (기준: ${pm25Thr.toFixed(0)})`,
          title: '초미세먼지(PM2.5) 경보',
          body: `현재 ${pm25.toFixed(1)} µg/m³ (기준 ${pm25Thr.toFixed(0)}) · 환기 또는 공기청정기 가동 권장`,
        });
      }
      if (pm10 >= pm10Thr) {
        alerts.push({
          key: 'pm10', type: 'pm10', severity: 'warning', value: pm10,
          message: `미세먼지(PM10) 기준 초과: ${pm10.toFixed(1)} µg/m³ (기준: ${pm10Thr.toFixed(0)})`,
          title: '미세먼지(PM10) 경보',
          body: `현재 ${pm10.toFixed(1)} µg/m³ (기준 ${pm10Thr.toFixed(0)}) · 환기 또는 공기청정기 가동 권장`,
        });
      }
      // 온·습도는 DHT 정상 동작 시에만 (0 또는 비정상값 = 센서 오류 → 제외)
      if (hum > 0 && hum <= 100) {
        if (temp >= tHigh) {
          alerts.push({
            key: 'temperature', type: 'temperature', severity: 'warning', value: temp,
            message: `고온 경보: ${temp.toFixed(1)} °C (기준: ${tHigh}°C 이상)`,
            title: '고온 경보', body: `현재 ${temp.toFixed(1)} °C (기준 ${tHigh}°C 이상)`,
          });
        } else if (temp <= tLow) {
          alerts.push({
            key: 'temperature', type: 'temperature', severity: 'warning', value: temp,
            message: `저온 경보: ${temp.toFixed(1)} °C (기준: ${tLow}°C 이하)`,
            title: '저온 경보', body: `현재 ${temp.toFixed(1)} °C (기준 ${tLow}°C 이하)`,
          });
        }
        if (hum > hHigh) {
          alerts.push({
            key: 'humidity', type: 'humidity', severity: 'warning', value: hum,
            message: `고습도 경보: ${hum.toFixed(1)} % (기준: ${hHigh}% 초과)`,
            title: '고습도 경보', body: `현재 ${hum.toFixed(1)} % (기준 ${hHigh}% 초과)`,
          });
        } else if (hum < hLow) {
          alerts.push({
            key: 'humidity', type: 'humidity', severity: 'warning', value: hum,
            message: `저습도 경보: ${hum.toFixed(1)} % (기준: ${hLow}% 미만)`,
            title: '저습도 경보', body: `현재 ${hum.toFixed(1)} % (기준 ${hLow}% 미만)`,
          });
        }
      }
      if (co2 >= co2DangerThr) {
        alerts.push({
          key: 'co2', type: 'co2', severity: 'danger', value: co2,
          message: `이산화탄소(CO₂) 위험: ${co2.toFixed(0)} ppm (기준: ${co2DangerThr.toFixed(0)} 이상) · 즉시 환기 필요`,
          title: '이산화탄소(CO₂) 위험',
          body: `현재 ${co2.toFixed(0)} ppm (기준 ${co2DangerThr.toFixed(0)}) · 즉시 환기하세요 · 졸음·두통 유발`,
        });
      } else if (co2 >= co2WarnThr) {
        alerts.push({
          key: 'co2', type: 'co2', severity: 'warning', value: co2,
          message: `이산화탄소(CO₂) 주의: ${co2.toFixed(0)} ppm (기준: ${co2WarnThr.toFixed(0)} 이상) · 환기 권장`,
          title: '이산화탄소(CO₂) 주의',
          body: `현재 ${co2.toFixed(0)} ppm (기준 ${co2WarnThr.toFixed(0)}) · 창문 개방 환기를 권장합니다`,
        });
      }

      // ── alert_state 구조 ──
      // {key}_sent : 마지막 알람을 보낸 센서 timestamp
      //   - 없음(0): 아직 한 번도 안 보냄 → 즉시 발송
      //   - 있음:    sensorTs - sent >= 5분이면 재발송
      //   - 정상 복귀 시: 삭제 (다음 초과 때 즉시 발송)
      const state = (await rtdbGet(env, accessToken, `alert_state/${deviceId}`)) || {};
      const newState = { ...state };
      const now = Date.now();

      // 센서 측정 시각 (ESP32 NTP timestamp 우선, 없으면 현재 시각)
      const sensorTs = num(data.timestamp, 0) > 1000000000000
        ? num(data.timestamp)
        : num(data.timestamp) * 1000 || now;

      const allKeys = ['pm25', 'pm10', 'temperature', 'humidity', 'co2'];
      const exceededKeys = new Set(alerts.map((a) => a.key));

      // ── 정상 복귀 항목: sent 초기화 (다음 초과 시 즉시 발송 준비) ──
      for (const key of allKeys) {
        if (!exceededKeys.has(key)) {
          delete newState[`${key}_sent`];
        }
      }

      if (alerts.length === 0) {
        await rtdbPut(env, accessToken, `alert_state/${deviceId}`, newState);
        return json({ ok: true, sent: 0, reason: 'within thresholds' });
      }

      // ── 초과 항목 판정 ──
      // 처음 초과(sent 없음) → 즉시 발송
      // 이미 발송된 적 있음  → sensorTs 기준 5분 경과 시 재발송
      const toSend = [];
      for (const alert of alerts) {
        const lastSent = num(state[`${alert.key}_sent`], 0);
        if (lastSent === 0 || sensorTs - lastSent >= REPEAT_MS) {
          toSend.push(alert);
        }
      }

      if (toSend.length === 0) {
        await rtdbPut(env, accessToken, `alert_state/${deviceId}`, newState);
        const status = alerts.map((a) => {
          const lastSent = num(newState[`${a.key}_sent`], sensorTs);
          const remaining = Math.max(0, Math.ceil((REPEAT_MS - (sensorTs - lastSent)) / 60000));
          return `${a.key}(${remaining}분 후 재알람)`;
        });
        return json({ ok: true, sent: 0, reason: 'cooldown', status });
      }

      // ── 1) Firestore에 인앱 경보 기록 (토큰 유무와 무관하게 항상 기록) ──
      //    시각은 센서 측정 시각(sensorTs)으로 기록 → 앱에서 "몇 분 전" 계산의 기준
      const recorded = [];
      for (const alert of toSend) {
        await writeFirestoreAlert(env, accessToken, alert, deviceId, sensorTs);
        newState[`${alert.key}_sent`] = sensorTs; // 5분 후 재알람 판단 기준
        recorded.push(alert.key);
      }

      // ── 2) FCM 푸시 발송 (토큰 있을 때만, 베스트에포트) ──
      const tokensMap = (await rtdbGet(env, accessToken, 'fcm_tokens')) || {};
      const tokens = Object.values(tokensMap)
        .map((t) => (t && t.token) || null)
        .filter(Boolean);
      const uniqueTokens = [...new Set(tokens)];

      let sent = 0;
      const invalidTokens = [];
      const fcmErrors = [];
      for (const alert of toSend) {
        for (const token of uniqueTokens) {
          const res = await sendFcm(env, accessToken, token, alert.title, alert.body, {
            type: alert.key,
            deviceId,
          });
          if (res.ok) {
            sent++;
          } else {
            fcmErrors.push({ key: alert.key, status: res.status, error: res.error });
            if (res.invalid) invalidTokens.push(token);
          }
        }
      }

      await rtdbPut(env, accessToken, `alert_state/${deviceId}`, newState);

      // 만료/무효 토큰 정리
      for (const bad of [...new Set(invalidTokens)]) {
        await rtdbDelete(env, accessToken, `fcm_tokens/${sanitize(bad)}`);
      }

      return json({ ok: true, recorded, sent, alerts: toSend.map((a) => a.key), ...(fcmErrors.length > 0 && { fcmErrors }) });
    } catch (e) {
      return json({ error: String(e && e.message ? e.message : e) }, 500);
    }
  },
};

// ── Firestore REST: 인앱 경보 문서 생성 ──
// Flutter AlertModel.fromFirestore가 읽는 필드 형식과 일치시킨다.
async function writeFirestoreAlert(env, token, alert, deviceId, sensorTs) {
  const url = `https://firestore.googleapis.com/v1/projects/${env.FB_PROJECT_ID}/databases/(default)/documents/alerts`;
  const doc = {
    fields: {
      type: { stringValue: alert.type },
      severity: { stringValue: alert.severity },
      value: { doubleValue: alert.value },
      message: { stringValue: alert.message },
      timestamp: { timestampValue: new Date(sensorTs).toISOString() },
      deviceId: { stringValue: deviceId },
      isRead: { booleanValue: false },
    },
  };
  const r = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(doc),
  });
  if (!r.ok) throw new Error(`Firestore write: ${r.status} ${await r.text()}`);
  return r.json();
}

// ── Firebase RTDB REST 헬퍼 ──
async function rtdbGet(env, token, path) {
  const url = `${env.FB_DATABASE_URL}/${path}.json?access_token=${token}`;
  const r = await fetch(url);
  if (!r.ok) throw new Error(`RTDB GET ${path}: ${r.status}`);
  return r.json();
}

async function rtdbPut(env, token, path, value) {
  const url = `${env.FB_DATABASE_URL}/${path}.json?access_token=${token}`;
  const r = await fetch(url, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(value),
  });
  if (!r.ok) throw new Error(`RTDB PUT ${path}: ${r.status}`);
  return r.json();
}

async function rtdbDelete(env, token, path) {
  const url = `${env.FB_DATABASE_URL}/${path}.json?access_token=${token}`;
  await fetch(url, { method: 'DELETE' });
}

// ── FCM HTTP v1 발송 ──
async function sendFcm(env, token, deviceToken, title, body, data) {
  const url = `https://fcm.googleapis.com/v1/projects/${env.FB_PROJECT_ID}/messages:send`;
  const strData = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, String(v)])
  );
  const message = {
    message: {
      token: deviceToken,
      notification: { title, body },
      data: strData,
      // Android 고우선순위
      android: { priority: 'high' },
      // 웹 푸시 (Chrome/Edge 등 브라우저 알림)
      webpush: {
        headers: { Urgency: 'high' },
        notification: {
          title,
          body,
          icon: '/icons/Icon-192.png',
          requireInteraction: true,
        },
      },
      // APNs (iOS/macOS Safari)
      apns: {
        headers: { 'apns-priority': '10' },
      },
    },
  };
  const r = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(message),
  });
  if (r.ok) return { ok: true };
  const errText = await r.text();
  // UNREGISTERED: 토큰 만료/삭제 → 정리 대상
  const invalid = r.status === 404 || /UNREGISTERED/i.test(errText);
  return { ok: false, invalid, status: r.status, error: errText };
}

// ── 서비스 계정 → OAuth2 access token (JWT RS256) ──
async function getAccessToken(env) {
  const nowSec = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: env.FB_CLIENT_EMAIL,
    scope: SCOPES,
    aud: 'https://oauth2.googleapis.com/token',
    iat: nowSec,
    exp: nowSec + 3600,
  };

  const enc = (obj) => base64url(new TextEncoder().encode(JSON.stringify(obj)));
  const unsigned = `${enc(header)}.${enc(claim)}`;

  const key = await importPrivateKey(env.FB_PRIVATE_KEY);
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned)
  );
  const jwt = `${unsigned}.${base64url(new Uint8Array(sig))}`;

  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!r.ok) throw new Error(`OAuth token: ${r.status} ${await r.text()}`);
  const tok = await r.json();
  return tok.access_token;
}

async function importPrivateKey(pem) {
  const clean = pem
    .replace(/\\n/g, '\n')
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const der = Uint8Array.from(atob(clean), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    der.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );
}

// ── 유틸 ──
function base64url(bytes) {
  let str = '';
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function sanitize(token) {
  return token.replace(/[.#$\[\]/]/g, '_');
}

function num(v, fallback = 0) {
  const n = typeof v === 'number' ? v : parseFloat(v);
  return Number.isFinite(n) ? n : fallback;
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
