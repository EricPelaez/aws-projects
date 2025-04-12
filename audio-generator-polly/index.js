const { PollyClient, SynthesizeSpeechCommand } = require("@aws-sdk/client-polly");
const { S3Client } = require("@aws-sdk/client-s3");
const { Upload } = require("@aws-sdk/lib-storage"); 

const polly = new PollyClient({});
const s3 = new S3Client({});

exports.handler = async (event) => {
    try {
        const text = event.text;

        const params = {
            Text: text,
            OutputFormat: "mp3",
            VoiceId: "Joanna",
        };

        // Synthesize speech using Polly
        const command = new SynthesizeSpeechCommand(params);
        const data = await polly.send(command);

        // Generate a unique key for the audio file
        const key = `audio-${Date.now()}.mp3`;

        // Use Upload to stream the audio file to S3
        const upload = new Upload({
            client: s3,
            params: {
                Bucket: "ep-polly-audio-storage", //Replace with your bucket name
                Key: key,
                Body: data.AudioStream, 
                ContentType: "audio/mpeg",
            },
        });

        await upload.done(); // Wait for upload to complete

        return {
            statusCode: 200,
            body: JSON.stringify({ message: `Audio file stored as ${key}` }),
        };
    } catch (error) {
        console.error("Error:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: "Internal server error" }),
        };
    }
};