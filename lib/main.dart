import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Aimer.dart';
import 'AimerService.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: MovieListScreen(),
    );
  }
}

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({Key? key}) : super(key: key);

  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  List<Map<String, dynamic>> movies = [];
  List<Aimer> likedMovies = [];
  String searchQuery = '';
  String yearQuery = '';
  bool isLoading = false;

  final AimerService aimerService = AimerService();

  @override
  void initState() {
    super.initState();
    fetchMovies('Batman', year: '2024');
    fetchLikedMovies();
  }

  Future<void> fetchMovies(String query, {String year = ''}) async {
    setState(() {
      isLoading = true;
    });

    final url =
        'http://www.omdbapi.com/?s=$query&apikey=df27b2e4${year.isNotEmpty ? '&y=$year' : ''}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['Response'] == 'True') {
        setState(() {
          movies = (data['Search'] as List)
              .map((movie) => {
            "title": movie['Title'],
            "year": movie['Year'],
            "poster": movie['Poster'],
          })
              .toList();
        });
      } else {
        setState(() {
          movies = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No movies found!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      throw Exception('Failed to load movies');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchLikedMovies() async {
    try {
      List<Aimer> fetchedMovies = await aimerService.getAllAimers();
      setState(() {
        likedMovies = fetchedMovies;
      });
    } catch (e) {
      print('Error fetching liked movies: $e');
    }
  }

  Future<void> likeMovie(Map<String, dynamic> movie) async {
    Aimer newLikedMovie = Aimer(
      id: '',
      title: movie['title'],
      year: movie['year'],
      poster: movie['poster'],
    );

    await aimerService.createAimer(newLikedMovie);
    fetchLikedMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Search'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LikedMoviesScreen(likedMovies: likedMovies),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search for a movie',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (searchQuery.isNotEmpty) {
                      fetchMovies(searchQuery, year: yearQuery);
                    }
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Enter year (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  yearQuery = value;
                });
              },
            ),
          ),
          isLoading
              ? Center(
            child: Container(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
              ),
            ),
          )
              : Expanded(
            child: movies.isEmpty
                ? Center(
              child: Text(
                'No movies to display',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
                : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                final isLiked = likedMovies.any(
                        (likedMovie) => likedMovie.title == movie['title']);

                return Card(
                  elevation: 6,
                  margin: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        movie['poster'],
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey,
                            width: 80,
                            height: 120,
                            child: Icon(Icons.error,
                                color: Colors.red),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      movie['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('Year: ${movie['year']}'),
                    trailing: IconButton(
                      icon: Icon(
                        isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                        isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () async {
                        if (!isLiked) {
                          await likeMovie(movie);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LikedMoviesScreen extends StatelessWidget {
  final List<Aimer> likedMovies;

  const LikedMoviesScreen({required this.likedMovies});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Movies'),
        centerTitle: true,
      ),
      body: likedMovies.isEmpty
          ? Center(
        child: Text('No liked movies yet'),
      )
          : ListView.builder(
        itemCount: likedMovies.length,
        itemBuilder: (context, index) {
          final movie = likedMovies[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              leading: Image.network(movie.poster, width: 50),
              title: Text(movie.title),
              subtitle: Text('Year: ${movie.year}'),
            ),
          );
        },
      ),
    );
  }
}
