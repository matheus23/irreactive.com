require('dotenv').config()
const fetch = require('node-fetch')
const { EMAIL_TOKEN } = process.env
exports.handler = async (event, context, callback) => {
    const formName = event.queryStringParameters['form-name'];
    const email = event.queryStringParameters.email;
    if (formName !== 'email-subscription') {
        return { statusCode: 404, body: `Unknown form: ${formName}` };
    }
    console.log(`Recieved a submission: ${email}`)
    console.log(`Is there an email token? ${EMAIL_TOKEN != null}`)
    return fetch('https://api.buttondown.email/v1/subscribers', {
        method: 'POST',
        headers: {
            Authorization: `Token ${EMAIL_TOKEN}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
    })
        .then(response => response.json())
        .then(data => {
            console.log(`Submitted to Buttondown:\n ${JSON.stringify(data)}`)
        })
        .catch(error => ({ statusCode: 422, body: String(error) }))
}