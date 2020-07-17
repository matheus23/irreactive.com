require('dotenv').config()
const fetch = require('node-fetch')
const { EMAIL_TOKEN } = process.env

exports.handler = async (event, context, callback) => {
    const formName = event.queryStringParameters['form-name'];
    const email = event.queryStringParameters.email;

    if (formName !== 'email-subscription') {
        return {
            statusCode: 404,
            body: `Unknown form: ${formName}`
        };
    }
    if (EMAIL_TOKEN == null) {
        return {
            statusCode: 500,
            body: `Cannot submit to buttondown: Missing EMAIL_TOKEN`
        };
    }

    console.log(`Recieved a submission: ${email}`)
    try {
        const response = await fetch('https://api.buttondown.email/v1/subscribers', {
            method: 'POST',
            headers: {
                Authorization: `Token ${EMAIL_TOKEN}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ email }),
        });
        console.log(`Submitted to Buttondown:\n ${JSON.stringify(response.json())}`);
        return {
            statusCode: 200,
            body: `Successfully submitted ${email} to buttondown`
        };
    } catch (error) {
        return {
            statusCode: 422,
            body: String(error)
        };
    }
}
