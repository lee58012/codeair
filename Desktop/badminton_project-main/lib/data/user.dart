class BaddyUser{
  final String email;
  final String password;
  final String name;
  String groupId;
  late String type;
  late String uid;
  List<String> recentMatches;
  int totalGames;
  int wins;
  String winRate;

  BaddyUser({
    required this.email, 
    required this.password, 
    this.name = '', 
    this.groupId = '',
    this.recentMatches = const [],
    this.totalGames = 0,
    this.wins = 0,
    this.winRate = '0.0',
  });
}