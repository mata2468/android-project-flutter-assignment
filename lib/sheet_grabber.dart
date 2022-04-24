import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:wet2/auth_firebase.dart';

class Grabber extends StatefulWidget {
  final AuthFirebase authFirebaseProvider;
  final SnappingSheetController snappingSheetController;


  const Grabber({Key? key, required this.authFirebaseProvider, required this.snappingSheetController}) : super(key: key);

  @override
  State<Grabber> createState() => _GrabberState();
}

class _GrabberState extends State<Grabber> {
  
  bool _isGrabbed = false;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: _isGrabbed ? 5 : 0,
        sigmaY: _isGrabbed ? 5 : 0,
      ),
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              spreadRadius: 10,
              color: Colors.black,
            )
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
            bottomLeft: Radius.zero,
            bottomRight: Radius.zero
          ),
          color: Colors.grey
        ),
        child: Transform.rotate(
            angle: 0,
            child: Row(
              children: [
                const SizedBox(width: 10,),
                Expanded(child: Text("Welcome Back, " + widget.authFirebaseProvider.email!)),
                GestureDetector(
                    child: _isGrabbed ? const Icon(Icons.arrow_downward) : const Icon(Icons.arrow_upward),
                    onTap: () {
                      setState((){
                        if(!_isGrabbed){
                          widget.snappingSheetController.snapToPosition(const SnappingPosition.factor(positionFactor: 0.25));
                        } else {
                          widget.snappingSheetController.snapToPosition(const SnappingPosition.factor(positionFactor: 0.05));
                        }
                        _isGrabbed = !_isGrabbed;
                      });
                    },
                ),
                const SizedBox(width: 30)
              ],
            )
        ),
      ),
    );
  }
}
