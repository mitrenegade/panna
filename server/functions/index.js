const functions = require('firebase-functions');
const admin = require('firebase-admin');
const logging = require('@google-cloud/logging')();
const app = require('express')
const moment = require('moment')

admin.initializeApp(functions.config().firebase);

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
        return event.data.adminRef.child('error').set(error)
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
    console.log("createStripeSubscription for organizer " + organizerId + " charge id " + chargeId)
    // This onWrite will trigger whenever anything is written to the path, so
    // noop if the charge was deleted, errored out, or the Stripe API returned a result (id exists) 
    if (val === null || val.id || val.error) return null;
    // Look up the Stripe customer id written in createStripeCustomer
    return admin.database().ref(`/stripe_customers/${organizerId}/customer_id`).once('value').then(snapshot => {
        return snapshot.val();
    }).then(customer => {
        // Create a charge using the chargeId as the idempotency key, protecting against double charges 
        var date = Date.now()
        const trialMonths = 2
        const trialEnd = date.setMonth(date.getMonth() + trialMonths)

        var subscription = {customer: customer, items:[{plan: "basic-monthly"}], trial_end:trianEnd};
        console.log("createStripeSubscription amount " + amount + " customer " + customer)

        return stripe.subscriptions.create(subscription, {idempotency_key});
    }).then(response => {
        // If the result is successful, write it back to the database
        console.log("createStripeSubscription success with response " + response)
        return event.data.adminRef.update(response);
    }, error => {
        // We want to capture errors and render them in a user-friendly way, while
        // still logging an exception with Stackdriver
        console.log("createStripeSubscription error " + error)
        return event.data.adminRef.child('error').set(error)
    });
});

// cron job
exports.daily_job =
  functions.pubsub.topic('daily-tick').onPublish((event) => {
    console.log("This job is ran every hour! " + Date.now())
  });