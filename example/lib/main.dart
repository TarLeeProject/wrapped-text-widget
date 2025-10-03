import 'package:flutter/material.dart';
import 'package:wrapped_text_widget/wrapped_text_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: WrappedTextWidget(
                        paragraph: paragraph,
                        left: 66,
                        top: 77,
                        padding: EdgeInsets.all(16),
                        child: Image.network(
                          'https://letsenhance.io/static/73136da51c245e80edc6ccfe44888a99/396e9/MainBefore.jpg',
                          width: 123,
                          height: 65,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(color: Colors.black, width: 200, height: 123),
                    Container(color: Colors.pink, width: 400, height: 123),
                    Container(color: Colors.black, width: 300, height: 123),
                    Container(color: Colors.pink, width: 500, height: 123),
                  ],
                ),
              ),
            ),
            Container(color: Colors.yellow, width: 213, height: 56),
          ],
        ),
      ),
    );
  }
}

const paragraph =
    '''The sunset painted the sky in hues of orange, pink, and purple, casting a warm glow over the landscape. As the sun dipped below the horizon, the clouds transformed into cotton candy wisps, drifting lazily in the evening breeze. The air was filled with the sweet scent of blooming jasmine, and the soft chirping of crickets began to fill the silence, creating a serene atmosphere that invited reflection and peace.
The sunset painted the sky in hues of orange, pink, and purple, casting a warm glow over the landscape. As the sun dipped below the horizon, the clouds transformed into cotton candy wisps, drifting lazily in the evening breeze. The air was filled with the sweet scent of blooming jasmine, and the soft chirping of crickets began to fill the silence, creating a serene atmosphere that invited reflection and peace. The sunset painted the sky in hues of orange, pink, and purple, casting a warm glow over the landscape. As the sun dipped below the horizon, the clouds transformed into cotton candy wisps, drifting lazily in the evening breeze. 
The air was filled with the sweet scent of blooming jasmine, and the soft chirping of crickets began to fill the silence, creating a serene atmosphere that invited reflection and peace. 
The sunset painted the sky in hues of orange, pink, and purple, casting a warm glow over the landscape. 
As the sun dipped below the horizon, the clouds transformed into cotton candy wisps, drifting lazily in the evening breeze. The air was filled with the sweet scent of blooming jasmine, and the soft chirping of crickets began to fill the silence, creating a serene atmosphere that invited reflection and peace.''';
