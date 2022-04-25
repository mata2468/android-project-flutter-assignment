import 'dart:ffi';
import 'dart:ui';
import 'dart:io' as f;
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:wet2/auth_firebase.dart';
import 'package:wet2/sheet_grabber.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';

class RansomWords extends StatefulWidget {
  const RansomWords({Key? key}) : super(key: key);

  @override
  State<RansomWords> createState() => _RansomWordsState();
}

class _RansomWordsState extends State<RansomWords> {
  final _suggestions = <WordPair>[];
  Set<WordPair> _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);
  final SnappingSheetController snappingSheetController = SnappingSheetController();
  var _image = "https://firebasestorage.googleapis.com/v0/b/hellome-66cf9.appspot.com/o/default.png?alt=media&token=7096d5a8-4a0a-4067-a432-28aac55b8832";

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthFirebase>(
      builder: (context, authFirebaseProvider, child) =>
          Scaffold(
            appBar: AppBar(
              title: const Text('Startup Name Generator'),
              actions: [
                IconButton(onPressed: _pushSaved,
                  icon: const Icon(Icons.star),
                  tooltip: 'Saved Suggestions',
                ),
                authFirebaseProvider.isAuthenticated ? IconButton(onPressed: () {
                    authFirebaseProvider.logOut(); ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Successfully logged out")));
                    }
                    , icon: const Icon(Icons.exit_to_app))
                    : IconButton(onPressed: () {
                      _image = "https://firebasestorage.googleapis.com/v0/b/hellome-66cf9.appspot.com/o/default.png?alt=media&token=7096d5a8-4a0a-4067-a432-28aac55b8832";
                      Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    icon: const Icon(Icons.login))
              ],
            ),
            body: authFirebaseProvider.isAuthenticated ? SnappingSheet(
              lockOverflowDrag: true,
              snappingPositions: const [
                SnappingPosition.factor(positionFactor: 0.05),
                SnappingPosition.factor(positionFactor: 0.25)
              ],
              controller: snappingSheetController,
              sheetBelow: SnappingSheetContent(
                sizeBehavior: const SheetSizeFill(),
                draggable: false,
                child: Container(
                  child: SingleChildScrollView(
                    child: Row(
                      children: [
                        const SizedBox(width: 40,),
                        FutureBuilder(
                          future: _getImageFromDB(authFirebaseProvider),
                          builder: (context, _) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: NetworkImage(_image), fit: BoxFit.fill),
                            ),
                          ),
                        ),
                        const SizedBox(width: 80),
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 30,),
                              Text(authFirebaseProvider.email!),
                              const SizedBox(height: 20,),
                              ElevatedButton(
                                child: const Text("Change avatar"),
                                onPressed: () async {
                                  ImagePicker _picker = ImagePicker();
                                  XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    await authFirebaseProvider.uploadImage(f.File(image.path));
                                    _image = await authFirebaseProvider.getImage();
                                    setState(() {});
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("No image selected"))
                                    );
                                  }
                                },
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  color: Colors.white,
                ),
              ),
              grabbingHeight: 75,
              grabbing: Grabber(authFirebaseProvider: authFirebaseProvider, snappingSheetController: snappingSheetController,),
              child: FutureBuilder(
                  future: _getSaved(authFirebaseProvider),
                  builder: (context, _) => _buildSuggestions()),
            )
            : _buildSuggestions()),
          );
  }


  Widget _buildSuggestions(){
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, i){
          if(i.isOdd){
            return const Divider();
          }
          final index = i ~/ 2;
          if(index >= _suggestions.length){
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        }
    );
  }

  Widget _buildRow(WordPair pair){
    final alreadySaved = _saved.contains(pair);
    return Consumer<AuthFirebase>(
      builder: (context, authFirebaseProvider, child) =>
      ListTile(
        title: Text(
          pair.asPascalCase,
          style: _biggerFont,
        ),
        trailing: Icon(
          alreadySaved ? Icons.star : Icons.star_border,
          color: alreadySaved ? Colors.deepPurple : null,
          semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
        ),
        onTap: () {
          setState(() {
            if(alreadySaved){
              _saved.remove(pair);
              authFirebaseProvider.updateSavedSuggestions(_saved);
            } else{
              _saved.add(pair);
              authFirebaseProvider.updateSavedSuggestions(_saved);
          }});
        },
      ),
    );
  }

  _pushSaved(){
    bool _isDismissed = false;
    Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            final tiles = _saved.map((pair) {
              return Consumer<AuthFirebase>(
                builder: (context, authFirebaseProvider, child) =>
                Dismissible(
                  onDismissed: (_) {
                  setState(() {
                    _saved.remove(pair);
                    authFirebaseProvider.updateSavedSuggestions(_saved);
                  });

                  },
                  confirmDismiss: (direction) async{
                    await showDialog(context: context, builder: (context) =>
                        AlertDialog(
                          title: const Text("Delete Suggestion"),
                          content: Text("Are you sure you want to delete ${pair.asPascalCase} from your save suggestions?"),
                          actions: [
                            ElevatedButton(onPressed: (){
                              Navigator.pop(context, "Yes");
                              _isDismissed = true;
                            }
                                , child: const Text("Yes"),
                            style: ElevatedButton.styleFrom(
                            primary: Colors.deepPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),)
                        )),
                            ElevatedButton(onPressed: () {
                              Navigator.pop(context, "No");
                              _isDismissed = false;
                            }
                                , child: const Text("No"),
                            style: ElevatedButton.styleFrom(
                            primary: Colors.deepPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),)
                        ))
                          ],
                        )
                    );
                    return _isDismissed;
                  },
                  background: Container(
                    color: Colors.deepPurple,
                    child: Row(
                      children: const [
                        Icon(Icons.delete, color: Colors.white,),
                        Text("Delete Suggestion", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  key: ValueKey(pair.asPascalCase),
                  child: ListTile(
                    title: Text(
                      pair.asPascalCase,
                      style: _biggerFont,
                    ),
                  ),
                ),
              );
            },
            );
            final divided = tiles.isNotEmpty ? ListTile.divideTiles(
              context: context, tiles: tiles,).toList() : <Widget>[];
            return Scaffold(
                appBar: AppBar(
                  title: const Text('Saved Suggestions'),
                ),
                body: ListView(children: divided,),
            );
          },
        )
    );
  }

  Future<void>? _getSaved(AuthFirebase authFirebaseProvider) async {
      var s = (await authFirebaseProvider.getSavedSuggestions())["saved_suggestions"];
      _saved = {for (var toPair in s) WordPair(toPair.toString().split(' ')[0], toPair.toString().split(' ')[1])};
    //}
  }

  Future _getImageFromDB(AuthFirebase authFirebaseProvider) async{
    _image = (await authFirebaseProvider.getImage());
    print("************");
    print(_image);
    print("************");
  }



}