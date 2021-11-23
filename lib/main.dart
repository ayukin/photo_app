import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:photo_app/photo_list_screen.dart';
import 'package:photo_app/sign_in_screen.dart';

void main() async {
  // Flutterの初期化処理を待つ
  WidgetsFlutterBinding.ensureInitialized();

  // アプリ起動前にFirebase初期化処理を入れる
  // initializeApp()の返り値がFutureなので非同期処理
  // 非同期処理(Future)はawaitで処理が終わるのを待つことができる
  // ただし、awaitを使うときは関数にasyncを付ける必要がある
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // ログイン状態に応じて表示する画面を切り替える
      home: FirebaseAuth.instance.currentUser == null ? SignInScreen() : PhotoListScreen(),
    );
  }
}

