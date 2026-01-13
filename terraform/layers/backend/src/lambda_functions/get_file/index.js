const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { sdkStreamMixin } = require("@aws-sdk/util-stream-node");

const s3Client = new S3Client();

exports.handler = async (event) => {
    try {
        const userId = event.requestContext.authorizer.jwt.claims.sub; // email
        const fileId = event.pathParameters.id; // filename
        const resource = event.pathParameters.resource; //  users
        const rootFolder = event.pathParameters.rootFolder; // uploads
        const bucket = process.env.UPLOADS_BUCKET;

        // Get file from S3
        const response = await s3Client.send(
            new GetObjectCommand({
                Bucket: bucket,
                Key: `${rootFolder}/${resource}/${userId}/${fileId}`,
            })
        );

        // Convert stream to buffer
        const streamWithMixin = sdkStreamMixin(response.Body);
        const buffer = await streamWithMixin.transformToByteArray();

        return {
            statusCode: 200,
            body: buffer.toString("base64"),
            isBase64Encoded: true,
            headers: {
                "Content-Type": response.ContentType || "application/octet-stream",
                "Content-Disposition": `attachment; filename="${fileId}"`,
            },
        };
    } catch (error) {
        console.error("Error:", error);
        return {
            statusCode: error.name === "NoSuchKey" ? 404 : 500,
            body: JSON.stringify({ error: error.message }),
        };
    }
};