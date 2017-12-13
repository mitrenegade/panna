const functions = require('firebase-functions');
const admin = require('firebase-admin');
const logging = require('@google-cloud/logging')();
const app = require('express')
const moment = require('moment')
admin.initializeApp(functions.config().firebase);

// TO TOGGLE BETWEEN DEV AND PROD: change this to .dev or .prod for functions:config variables to be correct
const config = functions.config().dev
const stripe = require('stripe')(config.stripe.token)

exports.createStripeCustomer = functions.auth.user().onCreate(event => {
  const data = event.data;
  const email = data.email;
  const uid = data.uid;

  stripe.customers.create({
      email: email
    }, function(err, customer) {
        ref = `/stripe_customers/${uid}/customer_id`
        console.log('customer' + customer + 'err ' + err + ' ref ' + ref)
        return admin.database().ref(ref).set(customer.id);
  // asynchronously called
    });
});

exports.createStripeCustomerForLegacyUser = functions.https.onRequest( (req, res) => {
    const email = req.body.email
    const uid = req.body.id
    stripe.customers.create({
        email: email
    }, function(err, customer) {
        ref = `/stripe_customers/${uid}/customer_id`
        console.log('legacy customer' + customer + 'err ' + err + ' ref ' + ref)
        admin.database().ref(ref).set(customer.id);
        res.send(200, {'customer': customer, 'error':err})
    });
});

exports.ephemeralKeys = functions.https.onRequest( (req, res) => {
    console.log('Called ephemeral keys with ' + req.body.api_version + ' and ' + req.body.customer_id)
    const stripe_version = req.body.api_version;
    if (!stripe_version) {
        res.status(400).end();
        return;
    }
    // This function assumes that some previous middleware has determined the
    // correct customerId for the session and saved it on the request object.
    stripe.ephemeralKeys.create(
        {customer: req.body.customer_id},
        {stripe_version: stripe_version}
    ).then((key) => {
        res.status(200).json(key);
    }).catch((err) => {
        res.status(500).end();
    });
});

// Charge the Stripe customer whenever an amount is written to the Realtime database
exports.createStripeCharge = functions.database.ref(`/charges/events/{eventId}/{id}`).onWrite(event => {
//function createStripeCharge(req, res, ref) {
    const val = event.data.val();
    const userId = val.player_id
    const eventId = event.params.eventId
    const chargeId = event.params.id
    console.log("createStripeCharge for event " + eventId + " userId " + userId + " charge id " + chargeId)
    // This onWrite will trigger whenever anything is written to the path, so
    // noop if the charge was deleted, errored out, or the Stripe API returned a result (id exists) 
    if (val === null || val.id || val.error) return null;
    // Look up the Stripe customer id written in createStripeCustomer
    return admin.database().ref(`/stripe_customers/${userId}/customer_id`).once('value').then(snapshot => {
        return snapshot.val();
    }).then(customer => {
        // Create a charge using the pushId as the idempotency key, protecting against double charges 
        const amount = val.amount;
        const idempotency_key = chargeId;
        const currency = 'USD'
        let charge = {amount, currency, customer};
        if (val.source !== null) charge.source = val.source;
        console.log("createStripeCharge amount " + amount + " customer " + customer + " source " + val.source)
        return stripe.charges.create(charge, {idempotency_key});
    }).then(response => {
        // If the result is successful, write it back to the database
        console.log("createStripeCharge success with response " + response)
        return event.data.adminRef.update(response);
    }, error => {
        // We want to capture errors and render them in a user-friendly way, while
        // still logging an exception with Stackdriver
        console.log("createStripeCharge error " + error)
        return event.data.adminRef.child('error').set(error.message)
        // .then(() => {
        //   return reportError(error, {user: event.params.userId});
        // });
    });
});

exports.createStripeSubscription = functions.database.ref(`/charges/organizers/{organizerId}/{id}`).onWrite(event => {
//function createStripeCharge(req, res, ref) {
    const val = event.data.val();
    const organizerId = event.params.organizerId
    const chargeId = event.params.id
    var isTrial = val["isTrial"]
    if (!isTrial) {
        isTrial = false
    }
    const trialMonths = 1
    console.log("createStripeSubscription for organizer " + organizerId + " charge id " + chargeId + " isTrial " + isTrial)
    // This onWrite will trigger whenever anything is written to the path, so
    // noop if the charge was deleted, errored out, or the Stripe API returned a result (id exists) 
    if (val === null || val.id || val.error) return null;
    // Look up the Stripe customer id written in createStripeCustomer
    return admin.database().ref(`/stripe_customers/${organizerId}/customer_id`).once('value').then(snapshot => {
        return snapshot.val();
    }).then(customer => {
        // Create a charge using the chargeId as the idempotency key, protecting against double charges 
        const trialEnd = moment().add(trialMonths, 'months')
        const endDate = Math.floor(trialEnd.toDate().getTime()/1000) // to unix time

        var plan = "balizinha.organizer.monthly"
        var subscription = {customer: customer, items:[{plan: plan}]};
        if (isTrial) {
            plan = "balizinha.organizer.monthly.trial"
            subscription["trial_end"] = endDate
        }
        console.log("createStripeSubscription customer " + customer + " trialEnd " + endDate + " plan " + plan)

        return stripe.subscriptions.create(subscription);
    }).then(response => {
        // If the result is successful, write it back to the database
        console.log("createStripeSubscription success with response " + response)
        return event.data.adminRef.update(response);
    }, error => {
        // We want to capture errors and render them in a user-friendly way, while
        // still logging an exception with Stackdriver
        const trialEnd = moment().add(trialMonths, 'months')
        const endDate = Math.floor(trialEnd.toDate().getTime()/1000) // to unix time
        console.log("createStripeSubscription error " + error.message + " trial end " + endDate)
        return event.data.adminRef.update({"error": error.message, "status": "error", "deadline": endDate})
    });
});

// cron job
exports.daily_job =
  functions.pubsub.topic('daily-tick').onPublish((event) => {
    console.log("This job is run every day! " + Date.now())
  }
)

// a job set once in the past so that a cron job with a manual trigger can be used from google app engine's tasks
exports.testJob = functions.pubsub.topic('on-demand-tick').onPublish((event) => {
    var testToken = "eQuL09AtiCQ:APA91bHc5Yr4TQAOS8h6Sph1tCwIczrkWVf7u279xFxVpjUHaYksDwGTUUcnRk5jcTBFlWoLBs2AW9jAo8zJAdXyLD8kRqrtVjQWGSRBaOmJuN32SN-EE4-BqAp-IWDiB8O3otORC4wt"
    var msg = "test worked, sending test push to " + testToken
    console.log(msg)
    exports.sendPush(testToken, msg)
})

// event creation/change
exports.onEventChange = functions.database.ref('/events/{eventId}').onWrite(event => {
    const eventId = event.params.eventId
    var eventChanged = false
    var eventCreated = false
    var eventDeleted = false
    var data = event.data.val();

    if (!event.data.previous.exists()) {
        eventCreated = true
    } else if (data["active"] == false) {
        eventDeleted = true
    }

    if (!eventCreated && event.data.changed()) {
        eventChanged = true;
    }

    if (eventCreated == true) {
        var title = "New event available"
        var topic = "general"
        var name = data["name"]
        var city = data["city"]
        if (!city) {
            city = data["place"]
        }

        // send push
        var msg = "A new event, " + name + ", is available in " + city
        exports.sendPushToTopic(title, topic, msg)

        // subscribe owner to event topic
        var ownerId = data["owner"]
        if (ownerId) {
            return admin.database().ref(`/players/${ownerId}`).once('value').then(snapshot => {
                return snapshot.val();
            }).then(player => {
                var token = player["fcmToken"]
                var ownerTopic = "eventOwner" + eventId
                if (token && token.length > 0) {
                    exports.subscribeToTopic(token, ownerTopic)
                    return console.log("event: " + eventId + " created " + eventCreated + " subscxribing " + ownerId + " to " + ownerTopic)
                } else {
                    return console.log("event: " + eventId + " created " + eventCreated + " user " + ownerId + " did not have fcm token")
                }
            })
        } else {
            return console.log("event: " + eventId + " created " + eventCreated + " no owner id!")
        }
    } else if (eventDeleted == true) {
        var title = "Event cancelled"
        var topic = "event" + eventId
        var name = data["name"]
        var city = data["city"]
        if (!city) {
            city = data["place"]
        }

        // send push
        var msg = "An event you're going to, " + name + ", has been cancelled."
        return exports.sendPushToTopic(title, topic, msg)
    } else {
        return console.log("event: " + eventId + " created " + eventCreated + " changed " + eventChanged + " state: " + data)
    }
    // return admin.database().ref(`/players/${userId}`).once('value').then(snapshot => {
    //     return snapshot.val();
    // }).then(player => {
    //     var name = player["name"]
    //     var email = player["email"]
    //     var joinedString = "joined"
    //     if (!eventUserData) {
    //         joinedString = "left"
    //     }
    //     var msg = name + " has " + joinedString + " your game"
    //     var title = "Event update"
    //     var ownerTopic = "eventOwner" + eventId // join/leave message only for owners
    //     console.log("Sending push for user " + name + " " + email + " joined event " + ownerTopic + " with message: " + msg)

    //     var token = player["fcmToken"]
    //     var eventTopic = "event" + eventId
    //     if (token.length > 0) {
    //         if (eventUserData) {
    //             subscribeToTopic(token, topic)
    //         } else {
    //             unsubscribeFromTopic(token, topic)
    //         }
    //     }

    //     return exports.sendPushToTopic(title, ownerTopic, msg)
    // })
})

// join/leave event
exports.onUserJoinOrLeaveEvent = functions.database.ref('/eventUsers/{eventId}/{userId}').onWrite(event => {
    const eventId = event.params.eventId
    const userId = event.params.userId
    var eventUserChanged = false;
    var eventUserCreated = false;
    var eventUserData = event.data.val();

    if (!event.data.previous.exists()) {
        eventUserCreated = true;
    }
    if (!eventUserCreated && event.data.changed()) {
        eventUserChanged = true;
    }
    console.log("event: " + eventId + " user: " + userId + " state: " + eventUserData)

    return admin.database().ref(`/players/${userId}`).once('value').then(snapshot => {
        return snapshot.val();
    }).then(player => {
        var name = player["name"]
        var email = player["email"]
        var joinedString = "joined"
        if (!eventUserData) {
            joinedString = "left"
        }
        var msg = name + " has " + joinedString + " your game"
        var title = "Event update"
        var ownerTopic = "eventOwner" + eventId // join/leave message only for owners
        console.log("Sending push for user " + name + " " + email + " joined event " + ownerTopic + " with message: " + msg)

        var token = player["fcmToken"]
        var eventTopic = "event" + eventId
        if (token && token.length > 0) {
            if (eventUserData) {
                exports.subscribeToTopic(token, eventTopic)
            } else {
                exports.unsubscribeFromTopic(token, eventTopic)
            }
        }

        return exports.sendPushToTopic(title, ownerTopic, msg)
    })
})

// actions
exports.onAction = functions.database.ref('/action/{actionId}').onWrite(event => {
    const actionId = event.params.actionId
    var data = event.data.val();

    const eventId = data["event"]
    const userId = data["user"]
    const actionType = data["type"]

    if (actionType == "chat") {
        return exports.onChatAction(actionId, eventId, userId, data)
    } else {
        return
    }
})

exports.onChatAction = function(actionId, eventId, userId, data) {
    console.log("action: " + actionId + " event: " + eventId + " user: " + userId + " data: " + data)

    var eventTopic = "event" + eventId
    return admin.database().ref(`/players/${userId}`).once('value').then(snapshot => {
        return snapshot.val();
    }).then(player => {
        var name = player["name"]
        var email = player["email"]
        var message = data["message"]
        var msg = name + " said: " + message
        var title = "Event chat"
        var topic = "event" + eventId 
        console.log("Sending push for user " + name + " " + email + " for chat to topic " + topic + " with message: " + msg)

        return exports.sendPushToTopic(title, topic, msg)
    })
}

// Push
exports.sendPushToTopic = function(title, topic, msg) {
        var topicString = "/topics/" + topic
        // topicString = topicString.replace(/-/g , '_');
        console.log("send push to topic " + topicString)
        var payload = {
            notification: {
                title: title,
                body: msg,
                sound: 'default',
                badge: '1'
            }
        };
        return admin.messaging().sendToTopic(topicString, payload);
}

exports.sendPush = function(token, msg) {
        //var testToken = "duvn2V1qsbk:APA91bEEy7DylD9iZctBtaKz5nS9CVZxpaAdaPwhIauzQ2jw81BF-oE0nhgvN3U10mqClTue0siwDH41JZP2kLqU0CkThOoBBdFQYWOr8X_6qHIknBE-Oa195qOy8XSbJvXeQj4wQa9T"
        
        var tokens = [token]
        console.log("send push to token " + token)
        var payload = {
            notification: {
                title: 'Firebase Notification',
                body: msg,
                sound: 'default',
                badge: "2"
            }
        };
        return admin.messaging().sendToDevice(tokens, payload);
}

exports.subscribeToTopic = function(token, topic) {
    admin.messaging().subscribeToTopic(token, topic)
        .then(function(response) {
        // See the MessagingTopicManagementResponse reference documentation
        // for the contents of response.
            console.log("Successfully subscribed " + token + " to topic: " + topic + " response " + response);
        })
        .catch(function(error) {
            console.log("Error subscribing to topic:", error);
        }
    );
}

exports.unsubscribeFromTopic = function(token, topic) {
    admin.messaging().unsubscribeFromTopic(registrationToken, topic)
        .then(function(response) {
        // See the MessagingTopicManagementResponse reference documentation
        // for the contents of response.
            console.log("Successfully unsubscribed " + token + " from topic: " + topic + " response " + response);
        })
        .catch(function(error) {
            console.log("Error unsubscribing from topic:", error);
        }
    );
}
