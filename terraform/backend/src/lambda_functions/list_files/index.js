const { S3Client, ListObjectsV2Command } = require("@aws-sdk/client-s3");
const { DynamoDBClient, QueryCommand } = require("@aws-sdk/client-dynamodb");

const s3Client = new S3Client();
const dynamoClient = new DynamoDBClient();

exports.handler = async (event) => {
    try {
        const userId = event.requestContext.authorizer.jwt.claims.sub; // Cognito user ID
        const bucket = process.env.UPLOADS_BUCKET;
        const tableName = process.env.DOCUMENTS_TABLE;

        // Get file list from S3
        const s3Response = await s3Client.send(
            new ListObjectsV2Command({
                Bucket: bucket,
                Prefix: `${userId}/`, // Files organized by user
            })
        );

        // Get metadata from DynamoDB
        const dynamoResponse = await dynamoClient.send(
            new QueryCommand({
                TableName: tableName,
                KeyConditionExpression: "userId = :userId",
                ExpressionAttributeValues: {
                    ":userId": { S: userId },
                },
            })
        );

        const files = (s3Response.Contents || []).map((file) => ({
            key: file.Key,
            size: file.Size,
            lastModified: file.LastModified,
        }));

        const metadata = (dynamoResponse.Items || []).map((item) => ({
            documentId: item.documentId.S,
            fileName: item.fileName.S,
            uploadedAt: item.uploadedAt.S,
        }));

        return {
            statusCode: 200,
            body: JSON.stringify({
                files,
                metadata,
            }),
            headers: {
                "Content-Type": "application/json",
            },
        };
    } catch (error) {
        console.error("Error:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message }),
        };
    }
};