require('dotenv').config()
const fetch = require('node-fetch')
const { EMAIL_TOKEN } = process.env

function getParameter(event, queryParam, payloadParam) {
    const queryParam = event.queryStringParameters[queryParam];
    if (queryParam != null) {
        return queryParam;
    }
    return JSON.parse(event.body).payload[payloadParam];
}

exports.handler = async (event, context, callback) => {
    const email = getParameter(event, 'email', 'email');
    const formName = getParameter(event, 'form-name', 'form_name');

    if (formName !== 'email-subscription') {
        throw new Error(`Unknown form: ${formName}`);
    }

    if (EMAIL_TOKEN == null) {
        throw new Error(`Cannot submit to buttondown: Missing EMAIL_TOKEN`);
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
        throw new Error(String(error));
    }
}
