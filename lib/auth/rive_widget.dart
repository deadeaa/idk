import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';

class RiveLoginController extends StatefulWidget {
  final String riveFile;

  const RiveLoginController({
    super.key,
    required this.riveFile,
  });

  @override
  State<RiveLoginController> createState() => RiveLoginControllerState();
}

class RiveLoginControllerState extends State<RiveLoginController> {
  StateMachineController? _smController;

  SMIInput<bool>? isFocusInput;
  SMIInput<bool>? isPasswordInput;
  SMIInput<bool>? loginSuccessInput;
  SMIInput<bool>? loginFailInput;

  void _onRiveInit(Artboard artboard) {

    print("State Machines:");
    for (var sm in artboard.stateMachines) {
      print("→ ${sm.name}");
      for (var input in sm.inputs) {
        print("   Input: ${input.name}");
      }
    }

    _smController =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');

    if (_smController != null) {
      artboard.addController(_smController!);

      isFocusInput = _smController!.findInput<bool>('isFocus');
      isPasswordInput = _smController!.findInput<bool>('IsPassword');
      loginSuccessInput = _smController!.findInput<bool>('login_success');
      loginFailInput = _smController!.findInput<bool>('login_fail');
    }
  }

  void setFocus(bool value) {
    isFocusInput?.value = value;
  }

  void setPassword(bool value) {
    isPasswordInput?.value = value;
  }

  void loginSuccess() {
    loginSuccessInput?.value = true;
    Timer(const Duration(seconds: 2), () {
      loginSuccessInput?.value = false;
    });
  }

  void loginFail() {
    loginFailInput?.value = true;
    Timer(const Duration(seconds: 2), () {
      loginFailInput?.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      widget.riveFile,
      fit: BoxFit.contain,
      onInit: _onRiveInit,
    );
  }
}
