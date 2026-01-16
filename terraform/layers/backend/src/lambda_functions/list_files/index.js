const { S3Client, ListObjectsV2Command } = require("@aws-sdk/client-s3");
const { DynamoDBClient, QueryCommand } = require("@aws-sdk/client-dynamodb");

const s3Client = new S3Client();
const dynamoClient = new DynamoDBClient();

exports.handler = async (event) => {
    try {
        const id = event.requestContext.authorizer.jwt.claims.sub; // Cognito user ID
        const bucket = process.env.UPLOADS_BUCKET;
        const tableName = process.env.DOCUMENTS_TABLE;

        // Get file list from S3
        const s3Response = await s3Client.send(
            new ListObjectsV2Command({
                Bucket: bucket,
                Prefix: `${id}/`, // Files organized by user
            })
        );

        // Get metadata from DynamoDB
        const dynamoResponse = await dynamoClient.send(
            new QueryCommand({
                TableName: tableName,
                KeyConditionExpression: "id = :id",
                ExpressionAttributeValues: {
                    ":id": { S: id },
                },
            })
        );

        // Build a map from DynamoDB metadata by fileKey
        const metadataMap = {};
        (dynamoResponse.Items || []).forEach((item) => {
            metadataMap[item.fileKey.S] = {
                documentId: item.id.S,
                resource: item.resource.S
            };
        });

        // Merge S3 files with DynamoDB metadata
        const combined = (s3Response.Contents || []).map((file) => {
            const meta = metadataMap[file.Key] || {};
            return {
                key: file.Key,
                size: file.Size,
                lastModified: file.LastModified,
                documentId: meta.documentId || null,
                resource: meta.resource || null
            };
        });

        return {
            statusCode: 200,
            body: JSON.stringify({
                files: combined
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