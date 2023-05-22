import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'globals.dart';

/// [StatelessWidget] displaying information about Baseflow
class InfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          child: Padding(
            padding: defaultHorizontalPadding + defaultVerticalPadding,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("OptimizedCachedImage by humblerookie"),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                ),
                Text(
                  'This app showcases the possibilities of the $pluginName '
                  'plugin. '
                  'This plugin is available as open source project on Github. '
                  '\n\n'
                  'Need help with integrating functionalities within your own '
                  'apps? Contact us at anvithv4@gmail.com',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                _launcherRaisedButton(
                  'Find us on Github',
                  githubURL,
                  context,
                ),
                _launcherRaisedButton(
                  'Find us on pub.dev',
                  pubDevURL,
                  context,
                ),
                _launcherRaisedButton(
                  'Visit anvith.dev',
                  baseflowURL,
                  context,
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _launcherRaisedButton(String text, String url, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      margin: const EdgeInsets.only(top: 24.0),
      alignment: Alignment.center,
      child: SizedBox.expand(
        child: ElevatedButton(
          child: Text(text),
          onPressed: () => _launchURL(url),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
