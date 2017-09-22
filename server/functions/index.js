const functions = require('firebase-functions');
const admin = require('firebase-admin');
const logging = require('@google-cloud/logging')();
const app = require('express')

admin.initializeApp(functions.config().firebase);

//const stripeModule = require('./stripe.js')
const config = functions.config().dev
const stripe = require('stripe')(config.stripe.token)

exports.testLog = functions.database.ref('/events')
    .onWrite(event => {
      // Grab the current value of what was written to the Realtime Database.
        console.log('testLog')
      return admin.database().ref('/logs/functions').set('yep2');
    });

// exports.createStripeCustomer = functions.auth.user().onCreate(event => {
//   const data = event.data;
//   const email = data.email;
//   const uid = data.uid;
//   const ref = admin.database().ref(`/stripe_customers/${uid}/customer_id`)

//   return stripeModule.createStripeCustomerHandler(email, uid, ref)
// })

exports.createStripeCustomer = functions.auth.user().onCreate(event => {
  const data = event.data;
  const email = data.email;
  const uid = data.uid;

  // return stripe.customers.create({
  //   email: email
  // }).then(customer => {
  // 	console.log("createStripeCustomer " + data.uid + " email " + data.email)
  //   return admin.database().ref(`/stripe_customers/${data.uid}/customer_id`).set(customer.id);
  // });
  stripe.customers.create({
	  email: email
	}, function(err, customer) {
		ref = `/stripe_customers/${uid}/customer_id`
		console.log('customer' + customer + 'err ' + err + ' ref ' + ref)
		return admin.database().ref(ref).set(customer.id);
  // asynchronously called
	});
});

// Add a payment source (card) for a user by writing a stripe payment source token to Realtime database
exports.addPaymentSourceFunction = functions.https.onRequest( (req, res) => {
	token = req.body.token
	console.log('token ' + token)
	customerRef = admin.database().ref('/stripe_customers/${event.params.userId}/customer_id').once('value').then(snapshot => {
		customer = snapshot.val()
		stripe.sources.create({
			type: 'type',
			usage: 'reusable'
		}).then( source => {
			ref = `/stripe_customers/${uid}`
			admin.database().ref(ref).setValue({"source":source.id, "last4":source.last4, "brand": source.brand});
			res.send(200, {"source": source.id})
		})
	})
	stripe.customers.createSource
})

app.post(path, (req, res) => {
  const stripe_version = req.query.api_version;
  if (!stripe_version) {
    res.status(400).end();
    return;
  }
  // This function assumes that some previous middleware has determined the
  // correct customerId for the session and saved it on the request object.
  stripe.ephemeralKeys.create(
    {customer: req.customerId},
    {stripe_version: stripe_version}
  ).then((key) => {
    res.status(200).json(key);
  }).catch((err) => {
    res.status(500).end();
  });
});

exports.testFunction = functions.https.onRequest( (req, res) => {
  stripe.customers.create({
	  email: 'test@gmail.com'
	}, function(err, customer) {
		ref = '/stripe_customers/1234/customer_id'
		console.log('customer' + customer + 'err ' + err + ' ref ' + ref)
		admin.database().ref(ref).set(customer.id);
		res.send(200, {'customer': customer, 'error':err})
  // asynchronously called
	});
});