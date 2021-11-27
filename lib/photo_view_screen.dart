import 'package:flutter/material.dart';
import 'package:photo_app/photo.dart';

class PhotoViewScreen extends StatefulWidget {
  const PhotoViewScreen({
    Key? key,
    required this.photo,
    required this.photoList,
  }) : super(key: key);

  final Photo photo;
  final List<Photo> photoList;

  @override
  _PhotoViewScreenState createState() => _PhotoViewScreenState();

}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();

    final int initialPage = widget.photoList.indexOf(widget.photo);
    _controller = PageController(
      initialPage: initialPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBarの裏までbodyの表示エリアを広げる
      extendBodyBehindAppBar: true,
      // 透明なAppBarを作る
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 画像一覧
          PageView(
            controller: _controller,
            onPageChanged: (int index) => {},
            // 受け取った画像一覧を表示
            children: widget.photoList.map((Photo photo) {
              return Image.network(
                photo.imageURL,
                fit: BoxFit.cover,
              );
            }).toList(),
          ),

          // アイコンボタンを画像の手前に重ねる
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // フッター部分にグラデーションを入れてみる
              decoration: BoxDecoration(
                // 線形グラデーション
                gradient: LinearGradient(
                  // 下方向から上方向に向かってグラデーションさせる
                  begin: FractionalOffset.bottomCenter,
                  end: FractionalOffset.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.1],
                ),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 共有ボタン
                  IconButton(
                    onPressed: () => {},
                    color: Colors.white,
                    icon: Icon(Icons.share),
                  ),

                  // 削除ボタン
                  IconButton(
                    onPressed: () => {},
                    color: Colors.white,
                    icon: Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}