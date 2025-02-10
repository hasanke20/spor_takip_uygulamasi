import 'package:flutter/cupertino.dart';

class EmptyScreen extends StatefulWidget {
  const EmptyScreen({super.key});

  @override
  State<EmptyScreen> createState() => _EmptyScreenState();
}

class _EmptyScreenState extends State<EmptyScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '!!!Coming Soon!!!',
                style: TextStyle(
                  fontSize: 30,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
