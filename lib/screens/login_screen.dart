import 'package:flutter/material.dart';
import 'package:bcard3/components/components.dart';
import 'package:bcard3/constants.dart';
import 'package:bcard3/screens/welcome.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:bcard3/screens/home_screen.dart';
import 'package:bcard3/screens/defaultHome.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static String id = 'login_screen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  late String _email = ''; // Initialize the email variable
  late String _password = ''; // Initialize the password variable
  bool _saving = false;

  // Function to validate email format
  bool isValidEmail(String email) {
    final RegExp regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomeScreen.id);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _saving,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const TopScreenImage(screenImageName: 'welcome.png'),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const ScreenTitle(title: 'Entrar'),
                        CustomTextField(
                          textField: TextField(
                            onChanged: (value) {
                              _email = value;
                            },
                            style: const TextStyle(
                              fontSize: 20,
                            ),
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
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                            decoration: kTextInputDecoration.copyWith(
                              hintText: 'Password',
                            ),
                          ),
                        ),
                        CustomBottomScreen(
                          textButton: 'Entrar',
                          heroTag: 'login_btn',
                          question: 'Esqueceu a password?',
                          buttonPressed: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() {
                              _saving = true;
                            });

                            // Check if email is valid before attempting to log in
                            if (!isValidEmail(_email)) {
                              signUpAlert(
                                context: context,
                                onPressed: () {
                                  setState(() {
                                    _saving = false;
                                  });
                                },
                                title: 'Formato de email inválido',
                                desc: 'Insira um email válido.',
                                btnText: 'Tente de novo',
                              ).show();
                              return;
                            }

                            try {
                              await _auth.signInWithEmailAndPassword(
                                  email: _email, password: _password);

                              if (context.mounted) {
                                setState(() {
                                  _saving = false;
                                  Navigator.popAndPushNamed(
                                      context, CardHome.id);
                                });
                                Navigator.pushNamed(context, WelcomeScreen.id);
                              }
                            } catch (e) {
                              if (e is FirebaseAuthException) {
                                String errorMessage;
                                switch (e.code) {
                                  case 'wrong-password':
                                    errorMessage = 'Password esta incorreta.';
                                    break;
                                  case 'user-not-found':
                                    errorMessage = 'O utilizador não existe';
                                    break;
                                  default:
                                    errorMessage = 'Erro não definido.';
                                }

                                signUpAlert(
                                  context: context,
                                  onPressed: () {
                                    setState(() {
                                      _saving = false;
                                    });
                                    Navigator.popAndPushNamed(
                                        context, LoginScreen.id);
                                  },
                                  title: 'Erro de Login',
                                  desc: errorMessage,
                                  btnText: 'Tente outra vez',
                                ).show();
                              } else {
                                print('Error: $e'); // Log any other errors
                              }
                            }
                          },
                            questionPressed: () {
                              if (!isValidEmail(_email)) {
                                signUpAlert(
                                  context: context,
                                  onPressed: () {},
                                  title: 'Formato de email inválido',
                                  desc: 'Insira um email válido para resetar a senha.',
                                  btnText: 'Recomeçar',
                                ).show();
                                return;
                              }
                              signUpAlert(
                                onPressed: () async {
                                  try {
                                    await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
                                    signUpAlert(
                                      context: context,
                                      onPressed: () {},
                                      title: 'Email Enviado',
                                      desc: 'Um link de reset de senha foi enviado para o seu email.',
                                      btnText: 'OK',
                                    ).show();
                                  } catch (e) {
                                    signUpAlert(
                                      context: context,
                                      onPressed: () {},
                                      title: 'Erro',
                                      desc: 'Falha ao enviar o email de reset. Verifique o endereço e tente novamente.',
                                      btnText: 'Recomeçar',
                                    ).show();
                                  }
                                },
                                title: 'RESET a sua PASSWORD',
                                desc: 'Clique no botao para enviar um link de reset de senha para o seu email.',
                                btnText: 'Reset',
                                context: context,
                              ).show();
                            },
                        ),
                      ],
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