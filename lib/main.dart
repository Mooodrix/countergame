import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AdManager.dart';
import 'pubplun.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  AdManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter Game',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const CounterGame(),
    );
  }
}

class CounterGame extends StatefulWidget {
  const CounterGame({Key? key}) : super(key: key);

  @override
  _CounterGameState createState() => _CounterGameState();
}

class _CounterGameState extends State<CounterGame> with TickerProviderStateMixin {
  int _counter = 0;
  List<int> _bestScores = [];
  bool _isLoading = true; // Peut être utilisé pour afficher un indicateur de chargement si nécessaire
  bool _isDarkMode = false;
  int _selectedDuration = 10;
  bool _isGameActive = false;
  bool _isGameFinished = false;
  String _statusMessage = '';
  late DateTime _endTime;
  double _progress = 1.0;
  Timer? _timer;
  double _scale = 1.0;
  bool _tapButtonClicked = false;
  bool _showDurationModes = true;

  final AudioPlayer _audioPlayerEnd = AudioPlayer();
  int _partiesJouees = 0; // Nouvelle variable pour compter les parties jouées

  @override
  void initState() {
    super.initState();
    PubPlun.loadInterstitialAd(); // Charge l'annonce interstitielle
    AdManager.loadBannerAd(); // Charge la bannière
    _loadScores();
    _preloadSounds();
    Future.delayed(const Duration(seconds: 2), () {
      PubPlun.showInterstitialAd(); // Affiche l'annonce interstitielle après 2 secondes
      setState(() {
        _isLoading = false; // Marquer le chargement comme terminé
      });
    });
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? scores = prefs.getStringList('bestScores$_selectedDuration') ?? [];
    _bestScores = scores.map(int.parse).toList();
    _bestScores.sort((a, b) => b.compareTo(a));
  }

  Future<void> _saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> scores = prefs.getStringList('bestScores$_selectedDuration') ?? [];
    scores.add(score.toString());
    scores.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    if (scores.length > 3) {
      scores = scores.sublist(0, 3);
    }
    await prefs.setStringList('bestScores$_selectedDuration', scores);
  }

  Future<void> _preloadSounds() async {
    await _audioPlayerEnd.setSource(AssetSource('sounds/end.mp3'));
  }

  void _playEndSound() {
    _audioPlayerEnd.play(AssetSource('sounds/end.mp3'));
  }

  void _startGame() {
    setState(() {
      _counter = 0;
      _statusMessage = '';
      _isGameActive = true;
      _isGameFinished = false;
      _endTime = DateTime.now().add(Duration(seconds: _selectedDuration));
      _progress = 1.0;
      _tapButtonClicked = true;
      _showDurationModes = false;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress = (_endTime.difference(DateTime.now()).inSeconds / _selectedDuration);
        if (_progress <= 0) {
          timer.cancel();
          _isGameActive = false;
          _isGameFinished = true;
          _statusMessage = 'Fin de Partie ! Ton score : $_counter';
          _playEndSound();
          _saveScore(_counter);
          _loadScores();
          _showDurationModes = true;

          // Appelle la méthode pour gérer la fin de la partie
          _finPartie(); // Appelle la méthode pour gérer les annonces
        }
      });
    });
  }

  void _incrementCounter() {
    if (_isGameActive) {
      setState(() {
        _counter++;
        _scale = 1.2;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _scale = 1.0;
        });
      });
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _selectDuration(int duration) {
    setState(() {
      _selectedDuration = duration;
      _loadScores();
    });
  }

  void _resetGame() {
    setState(() {
      _counter = 0;
      _statusMessage = '';
      _isGameActive = false;
      _isGameFinished = false;
      _timer?.cancel();
      _tapButtonClicked = false;
      _showDurationModes = false;
    });
  }

  void _finPartie() {
    _partiesJouees++; // Incrémente le compteur de parties jouées

    // Vérifie si le nombre de parties jouées est un multiple de 3
    if (_partiesJouees % 3 == 0) {
      PubPlun.showInterstitialAd(); // Montre l'annonce interstitielle
      PubPlun.loadInterstitialAd(); // Recharge une nouvelle annonce interstitielle
    }
  }

  List<int> _availableDurations() {
    List<int> durations = [5, 10, 20, 30, 60];
    durations.remove(_selectedDuration);
    return durations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Counter Game', style: TextStyle(fontSize: 24)),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode
                      ? [const Color.fromARGB(255, 5, 5, 5), Colors.grey[900]!]
                      : [Colors.blue, Colors.grey[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AdManager.getBannerAdWidget(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (_isGameFinished)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: ElevatedButton(
                              onPressed: _resetGame,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 80),
                                backgroundColor: Colors.orangeAccent,
                                elevation: 5,
                                shadowColor: Colors.orangeAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Rejouer',
                                style: TextStyle(fontSize: 24, color: Colors.white),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        Text(
                          'Score: $_counter',
                          style: TextStyle(
                            fontSize: 32,
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (!_isGameFinished)
                          GestureDetector(
                            onTap: () {
                              if (!_isGameActive) {
                                _startGame();
                              }
                              _incrementCounter();
                            },
                            child: AnimatedScale(
                              scale: _scale,
                              duration: const Duration(milliseconds: 100),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_tapButtonClicked ? Colors.green : Colors.blue, Colors.deepPurple],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      spreadRadius: 5,
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Tap Me!',
                                  style: TextStyle(fontSize: 24, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        if (_showDurationModes)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  _buildDurationButton(5),
                                  _buildDurationButton(10),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  _buildDurationButton(20),
                                  _buildDurationButton(30),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  _buildDurationButton(60),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        if (_isGameActive || _isGameFinished)
                          Container(
                            width: 300,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: _progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _progress <= 0.3 ? Colors.red : Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        AnimatedOpacity(
                          opacity: _isGameFinished ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 24,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_bestScores.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? Colors.black54 : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Meilleurs Scores:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: _isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                ..._bestScores.map((score) => Text(
                                  score.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: _isDarkMode ? Colors.white : Colors.black,
                                  ),
                                )),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: FloatingActionButton(
                      onPressed: _toggleTheme,
                      child: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDurationButton(int duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () {
          _selectDuration(duration);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedDuration == duration ? Colors.orange : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text('$duration sec'),
      ),
    );
  }
}
