import 'package:flutter/material.dart';

class ExampleScreen extends StatefulWidget {

  const ExampleScreen({
    super.key, 
  });

  @override
  State<ExampleScreen> createState() => ExampleScreenState();

}

class ExampleScreenState extends State<ExampleScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Home Screen'),
          ],
        ),
      ),
    );
  }

}