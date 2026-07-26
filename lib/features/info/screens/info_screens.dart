import 'package:flutter/material.dart';

import '../../../shared/widgets/alibi_widgets.dart';

class HowAlibiWorksScreen extends StatelessWidget {
  const HowAlibiWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlibiInfoPage(
      title: 'How Alibi works',
      children: [
        AlibiInfoBlock(
          title: 'Choose the situation',
          body: 'Select who the message is for and what kind of commitment you need to leave.',
        ),
        AlibiInfoBlock(
          title: 'Set the tone',
          body: 'Keep it believable, make it dramatic, be direct or deliberately absurd.',
        ),
        AlibiInfoBlock(
          title: 'Include a detail',
          body: 'Enter a person, place or subject. Alibi weaves it into a complete sentence.',
        ),
        AlibiInfoBlock(
          title: 'Copy, share or save',
          body: 'Use the result immediately or bookmark it in your local library.',
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlibiInfoPage(
      title: 'About',
      children: [
        Text(
          'A cleaner way\nto cancel.',
          style: TextStyle(
            fontSize: 42,
            height: .98,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Alibi is a lightweight offline excuse generator built by Studio XIII.',
          style: TextStyle(fontSize: 17, height: 1.55),
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlibiInfoPage(
      title: 'Privacy',
      children: [
        AlibiInfoBlock(
          title: 'No account required',
          body: 'Alibi does not ask you to create an account or provide profile information.',
        ),
        AlibiInfoBlock(
          title: 'Generated locally',
          body: 'Excuses are assembled on your device from the built-in phrase library.',
        ),
        AlibiInfoBlock(
          title: 'Local storage only',
          body: 'History, favourites, settings and theme choice stay on your device.',
        ),
      ],
    );
  }
}
