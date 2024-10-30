import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bcard3/components/components.dart';
import 'package:bcard3/screens/home_screen.dart';
import 'package:bcard3/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcard3/constants.dart';
import 'package:loading_overlay/loading_overlay.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static String id = 'signup_screen';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  late String _email;
  late String _password;
  late String _confirmPass;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomeScreen.id);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _saving,
          progressIndicator: CircularProgressIndicator(
            color: Color(0xff004aad), // Set your desired color here
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TopScreenImage(screenImageName: 'signup.png'),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ScreenTitle(title: 'Registar'),
                          CustomTextField(
                            textField: TextField(
                              onChanged: (value) {
                                _email = value;
                              },
                              style: const TextStyle(fontSize: 20),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Email',
                              ),
                            ),
                          ),
                          CustomTextField(
                            textField: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                _password = value;
                              },
                              style: const TextStyle(fontSize: 20),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Password',
                              ),
                            ),
                          ),
                          CustomTextField(
                            textField: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                _confirmPass = value;
                              },
                              style: const TextStyle(fontSize: 20),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Confirmar Password',
                              ),
                            ),
                          ),
                          CustomBottomScreen(
                            textButton: 'Registar',
                            heroTag: 'signup_btn',
                            question: 'Já tem conta?',
                            buttonPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _saving = true;
                              });

                              try {
                                await _auth.createUserWithEmailAndPassword(email: _email, password: _password);

                                print('User created successfully');
                                // Navigate to login screen after successful signup
                                Navigator.of(context).pushReplacementNamed(LoginScreen.id);

                                // Show alert after successful navigation
                                signUpAlert(
                                  context: context,
                                  title: 'SUCCESSO',
                                  desc: 'Utilizador criado com sucesso',
                                  btnText: 'Login AGORA',
                                  onPressed: () {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                ).show();

                              } catch (e) {
                                print('Error creating user: $e'); // Log the error
                                setState(() {
                                  _saving = false; // Stop the loading overlay on error
                                });
                                showAlert(
                                  context: context,
                                  title: 'ERRO',
                                  desc: 'A palavra-passe necessita de 6 caracteres ou mais',
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ).show();
                              }
                            },
                            questionPressed: () async {
                              Navigator.of(context).pushReplacementNamed(LoginScreen.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}