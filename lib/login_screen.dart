import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_firebase.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen>{


  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoadingLogIn = false;
  bool _isLoadingSignUp = false;
  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: _buildLoginScreen(),
    );
  }

  Widget _buildLoginScreen(){
    final authFirebaseProvider = Provider.of<AuthFirebase>(context);
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Column(
        children: [
          const Text("Welcome to Startup Names Generator, please log in below"),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "Email"
            ),
          ),
          TextField(
            obscureText: true,
            controller: _passwordController,
            decoration: const InputDecoration(
                labelText: "Password"
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),)
                  ),
                  onPressed: () async {
                    setState(() {
                      _isLoadingLogIn = true;
                    });
                    bool succeededToLogIn = await authFirebaseProvider.logIn(_emailController.text, _passwordController.text);
                    setState(() {
                      _isLoadingLogIn = false;
                    });
                    if(succeededToLogIn){
                      Navigator.pop(context);
                    } else{
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("There was an error logging into the app"))
                      );
                    }
                  },
                  child: _isLoadingLogIn ? Row(
                    children: const [
                      SizedBox(width: 90,),
                      Text('Loading...', style: TextStyle(fontSize: 20),),
                      SizedBox(width: 10,),
                      CircularProgressIndicator(color: Colors.white,)
                      ]
                  ) : const Text("Log in")
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),)
                ),
                onPressed: () async {
                  showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const Text("Please confirm your password below:"),
                              TextFormField(
                                obscureText: true,
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                    labelText: "Password"
                                ),
                                validator: (_) {
                                  if(_confirmPasswordController.text != _passwordController.text){
                                    return "Passwords must match";
                                  }
                                  return null;
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                primary: Colors.deepPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),)),
                                onPressed: () async {
                                  if(_formKey.currentState!.validate()){
                                    setState(() {
                                      _isLoadingSignUp = true;
                                    });
                                    await authFirebaseProvider.signUp(_emailController.text, _passwordController.text);
                                    setState(() {
                                      _isLoadingSignUp = false;
                                    });
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  }
                                  },
                                  child: _isLoadingSignUp ? Row(
                                      children: const [
                                        SizedBox(width: 90,),
                                        Text('Loading...', style: TextStyle(fontSize: 20),),
                                        SizedBox(width: 10,),
                                        CircularProgressIndicator(color: Colors.white,)
                                      ]
                                  ) : const Text("Confirm")
                              ),
                            ],
                          ),
                        );
                      });
                },
                child: _isLoadingSignUp ? Row(
                    children: const [
                      SizedBox(width: 90,),
                      Text('Loading...', style: TextStyle(fontSize: 20),),
                      SizedBox(width: 10,),
                      CircularProgressIndicator(color: Colors.white,)
                    ]
                ) : const Text("New user? Click to sign up")
            ),
          ),
        ],
      ),
    );
  }
}
