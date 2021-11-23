import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photo_app/photo_list_screen.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {

  // Formのkeyを指定する場合は<FormState>としてGlobalKeyを定義する
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // メールアドレス用のTextEditingController
  final TextEditingController _emailController = TextEditingController();
  // パスワード用のTextEditingController
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        // Formのkeyに指定する
        key: _formKey,

        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            // Columnを使い縦に並べる
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Photo App",
                  style: Theme.of(context).textTheme.headline4,
                ),

                SizedBox(height: 16),

                // 入力フォーム（メールアドレス）
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "メールアドレス"),
                  keyboardType: TextInputType.emailAddress,

                  // メールアドレス用のバリデーション
                  validator: (String? value) {
                    // メールアドレスが入力されていない場合
                    if (value?.isEmpty == true) {
                      // 問題がある時はメッセージを返す
                      return "メールアドレスを入力して下さい";
                    }
                    // 問題がない時はnullを返す
                    return null;
                  },

                ),

                SizedBox(height: 8),

                // 入力フォーム（パスワード）
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: "パスワード"),
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,

                  // パスワード用のバリデーション
                  validator: (String? value) {
                    // パスワードが入力されていない場合
                    if (value?.isEmpty == true) {
                      // 問題がある時はメッセージを返す
                      return "パスワードを入力して下さい";
                    }
                    // 問題がない時はnullを返す
                    return null;
                  },
                ),

                SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  // ボタン（ログイン）
                  child: ElevatedButton(
                    onPressed: () => _onSignIn(),
                    child: Text("ログイン"),
                  ),
                ),

                SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  // ボタン（新規登録）
                  child: ElevatedButton(
                    onPressed: () => _onSignUp(),
                    child: Text("新規登録"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSignIn() async {

    try {
      // 入力内容を確認する
      if (_formKey.currentState?.validate() != true) {
        // エラーメッセージがあるため処理を中断する
        return;
      }

      // 新規登録と同じく入力された内容をもとにログイン処理を行う
      final String email = _emailController.text;
      final String password = _passwordController.text;
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PhotoListScreen(),
        ),
      );
      print("ログイン成功");
    } catch (e) {
      // 失敗したらエラーメッセージを表示
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("エラー"),
            content: Text(e.toString()),
          );
        },
      );
    }

    // 画像一覧画面に切り替え
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PhotoListScreen(),
      ),
    );
  }

  // 内部で非同期処理(Future)を扱っているのでasyncを付ける
  // この関数自体も非同期処理となるので返り値もFutureとする
  Future<void> _onSignUp() async {

    try {
      // 入力内容を確認する
      if (_formKey.currentState?.validate() != true) {
        // エラーメッセージがあるため処理を中断する
        return;
      }

      // メールアドレス・パスワードで新規登録
      // TextEditingControllerから入力内容を取得
      // Authenticationを使った複雑な処理はライブラリがやってくれる
      final String email = _emailController.text;
      final String password = _passwordController.text;
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

      // 画像一覧画面に切り替え
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PhotoListScreen(),
        ),
      );
      print("新規登録成功");
    } catch (e) {
      // 失敗したらエラーメッセージを表示
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("エラー"),
            content: Text(e.toString()),
          );
        },
      );
    }
  }

}