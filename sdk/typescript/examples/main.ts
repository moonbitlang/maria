import { Maria } from "../index.js";

async function main() {
    const maria = new Maria();

    try {
        for await (const event of maria.start("Hello?")) {
            if (event.method === "maria.agent.request_completed") {
                const content = event.params.message.content;
                if (content) {
                    console.log(content);
                }
            } else if (event.method === "maria.agent.post_tool_call") {
                const toolCall = event.params.tool_call;

                if (toolCall.type === "function" && toolCall.function) {
                    const toolName = toolCall.function.name;
                    const toolArgs = toolCall.function.arguments;

                    try {
                        const parsedArgs = JSON.parse(toolArgs);
                        console.log(
                            `% ${toolName} ${
                                JSON.stringify(parsedArgs, null, 2)
                            }`,
                        );
                    } catch (error) {
                        console.log(`% ${toolName} ${toolArgs}`);
                    }
                }

                for (const line of event.params.text.split("\n")) {
                    console.log(`> ${line}`);
                }
            }
        }
    } catch (error) {
        console.error("Error:", error);
        process.exit(1);
    }
}

main().catch(console.error);
