# TuneHue
Relax with music and colors

This app is a music player, which combines calmly moving gradients with an intuitive interface and integration with the device's existing music library. By accessing a device's iTunes library, TuneHue allows users to listening to music either on their device or via the cloud, and provides a familiar, straightforwward user experience. Playlists can be added to, changed, and deleted, and features like shake to shuffle are included. Multiple gradient options range from bright, energizing hues, to relaxing cool ones, to suit the user's mood.

## Dependencies
[AnimatedGradientView](https://github.com/rwbutler/AnimatedGradientView) is used in this project to create the moving gradient backgrounds. [Carthage](https://github.com/Carthage/Carthage) has been used as the dependency manager for this project - please refer to Carthage documentation for details.

The content of the Cartfile for this project is as follows:
```
github "rwbutler/AnimatedGradientView"
```

The "Adding frameworks to an application" section in the Carthage documentation provides more explicit instructions for setup than the brief guide offered by Nuke. Simply follow the steps in the "If you're building for iOS, tvOS, or watchOS" section on the Carthage. It explains every step and should make setup easy.

## Features
This app features a main view that acts as the music player interface. It contains familiar play control buttons, along with track information such as title, artist, and album art. Current playlist items can be shuffled (either with the button or the shake gesture) or set to repeat a single track, or by the entire list.

Media playing is handled via an MPMediaPlayerController. This allows the music player to integrate with the system, and show the current song as a now playing item on the lock screen, etc. Songs from the cloud can be played, and if the network connection is lost and the song can no longer play, the user will be notified. The current playlist is saved as it is added to/edited, so it is not lost if the app is closed.

The left-side buttons below open the media picker view (if access has been permitted) to add media, and the current playlist view, where upcoming song info can be reviewed. This view also allows deletion of items.

The right-side buttons toggle the button color theme - either black or white, which is initially set depending on the device's light or dark mode - and to change the animated color background. Some color themes are available for free, and some require an in-app purchase. 

In-app purchases use Storekit and a product request to retrieve items. A notice is displayed if the device does not support purchases, and a network monitor ensures the presence of a network connection before attempting a request. Upon success of the purchase, a file containing the gradient details is downloaded, then details are saved to Core Data. If a user removes the app from their device, for example, they can use the restore button to retrieve their previous purchases.

## Support
If you experience trouble using the app, have any questions, or simply want to contact me, you can contact me via email at kduncanwelke@gmail.com. I will be happy to discuss this project.
