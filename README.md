# KeepItCool
iOS 8 app for stopping awkward situations

Currently this app is a simple one-pager that lets you add contacts to a "blacklist" of sorts. When a contact is blacklisted, their phone number is modified (currently to a non existing one, soon to a Twilio one) so the user can't message/call them. You can remove a contact from the list by simply tapping on them in the list.

The end game for this is to automatically check a user's Foursquare and Untappd feeds and automatically move designated contacts into the list based on if we can guess that the user is drunk or not. The hueristics for that are still up in the air (I'm thinking 2 beers on Untappd or a check-in at a bar followed by still being near the geopoint 30 min lateer) but the basics work, yay.

A big caveat here is I'm not 100% sure if I can actually access the AddressBook when responding to a push notification, specially since on devices with TouchID a lot of things are locked if the device is locked. We'll find out soon enough!
