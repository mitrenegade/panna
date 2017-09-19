const functions = require('firebase-functions'),
      admin = require('firebase-admin'),
      logging = require('@google-cloud/logging')();
admin.initializeApp(functions.config().firebase);

// Stripe
//const config = firebase.config().prod // for prod environment
const config = firebase.config().dev // for dev environment
const stripe = require('stripe')(config.stripe.token)

const currency = 'USD';

// [START chargecustomer]
// Charge the Stripe customer whenever an amount is written to the Realtime database
exports.createStripeCharge = functions.database.ref('/stripe_customers/{userId}/charges/{id}').onWrite(event => {
  const val = event.data.val();
  // This onWrite will trigger whenever anything is written to the path, so
  // noop if the charge was deleted, errored out, or the Stripe API returned a result (id exists) 
  if (val === null || val.id || val.error) return null;
  // Look up the Stripe customer id written in createStripeCustomer
  return admin.database().ref(`/stripe_customers/${event.params.userId}/customer_id`).once('value').then(snapshot => {
    return snapshot.val();
  }).then(customer => {
    // Create a charge using the pushId as the idempotency key, protecting against double charges 
    const amount = val.amount;
    const idempotency_key = event.params.id;
    let charge = {amount, currency, customer};
    if (val.source !== null) charge.source = val.source;
    return stripe.charges.create(charge, {idempotency_key});
  }).then(response => {
      // If the result is successful, write it back to the database
      return event.data.adminRef.set(response);
    }, error => {
      // We want to capture errors and render them in a user-friendly way, while
      // still logging an exception with Stackdriver
      return event.data.adminRef.child('error').set(userFacingMessage(error)).then(() => {
        return reportError(error, {user: event.params.userId});
      });
    }
  );
});
// [END chargecustomer]]

// When a user is created, register them with Stripe
exports.createStripeCustomer = functions.auth.user().onCreate(event => {
  const data = event.data;
  return stripe.customers.create({
    email: data.email
  }).then(customer => {
    return admin.database().ref(`/stripe_customers/${data.uid}/customer_id`).set(customer.id);
  });
});

// Add a payment source (card) for a user by writing a stripe payment source token to Realtime database
exports.addPaymentSource = functions.database.ref('/stripe_customers/{userId}/sources/{pushId}/token').onWrite(event => {
  const source = event.data.val();
  if (source === null) return null;
  return admin.database().ref(`/stripe_customers/${event.params.userId}/customer_id`).once('value').then(snapshot => {
    return snapshot.val();
  }).then(customer => {
    return stripe.customers.createSource(customer, {source});
  }).then(response => {
      return event.data.adminRef.parent.set(response);
    }, error => {
      return event.data.adminRef.parent.child('error').set(userFacingMessage(error)).then(() => {
        return reportError(error, {user: event.params.userId});
      });
  });
});

// When a user deletes their account, clean up after them
exports.cleanupUser = functions.auth.user().onDelete(event => {
  return admin.database().ref(`/stripe_customers/${event.data.uid}`).once('value').then(snapshot => {
    return snapshot.val();
  }).then(customer => {
    return stripe.customers.del(customer);
  }).then(() => {
    return admin.database().ref(`/stripe_customers/${event.data.uid}`).remove();
  });
});


