
// https://developer.school/tutorials/how-to-use-the-flutter-stepper-widget-flutter-2-6-0#customising-the-stepper-controls

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: MyStatefulWidget(),
        ),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget(
      {Key? key,
        this.steps = const [
          Step(
            title: Text('Step 1 title'),
            content: Text('Content for Step 1...'),
            state: StepState.complete,
          ),
          Step(
            title: Text('Step 2 title'),
            content: Text('Content for Step 2...'),
            state: StepState.complete,
          ),
          Step(
            title: Text('Step 3 title'),
            content: Text('Content for Step 3....'),
            state: StepState.error,
          ),
          Step(
            title: Text('Step 4 title'),
            content: Text('Content for Step 4 & final.'),
          ),
        ]})
      : super(key: key);

  final List<Step> steps;

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  int _index = 0;

  _stepContinue() {
    if (_index <= 0 || _index < widget.steps.length) {
      setState(() {
        _index++;
      });
    }

    if (_index >= widget.steps.length) {
      setState(() {
        _index = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stepper(
      type: StepperType.horizontal,
      currentStep: _index,
      onStepCancel: () {
        if (_index > 0) {
          setState(() {
            _index--;
          });
        }
      },
      onStepContinue: _stepContinue,
      onStepTapped: (int index) {
        setState(() {
          _index = index;
        });
      },
      steps: widget.steps,
    );
  }
}

