const {
    DynamoDBClient,
    GetItemCommand,
} = require("@aws-sdk/client-dynamodb");

const dynamoClient = new DynamoDBClient();

exports.handler = async (event) => {
    try {
        const userId = event.requestContext.authorizer.jwt.claims.sub;
        const documentId = event.pathParameters.id;
        const tableName = process.env.DOCUMENTS_TABLE;

        const response = await dynamoClient.send(
            new GetItemCommand({
                TableName: tableName,
                Key: {
                    userId: { S: userId },
                    documentId: { S: documentId },
                },
            })
        );

        if (!response.Item) {
            return {
                statusCode: 404,
                body: JSON.stringify({ error: "Document not found" }),
            };
        }

        // Convert DynamoDB format to JSON
        const item = response.Item;
        const document = {
            userId: item.userId.S,
            documentId: item.documentId.S,
            fileName: item.fileName.S,
            uploadedAt: item.uploadedAt.S,
            ...Object.fromEntries(
                Object.entries(item).map(([key, value]) => [key, Object.values(value)[0]])
            ),
        };

        return {
            statusCode: 200,
            body: JSON.stringify(document),
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