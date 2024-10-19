# README

This README documents the steps necessary to get the application up and running.

## Ruby version

Specify the Ruby version used in the project.

## System dependencies

List any system dependencies required for the project.

## Configuration

### Environment Variables

This application requires the following environment variables to be set:

- `GROQ_API_KEY`: Your Groq API key for text summarization.

To set up these environment variables:

1. Create a `.env` file in the root directory of the project.
2. Add the following line to the `.env` file:
   ```
   GROQ_API_KEY=your_groq_api_key_here
   ```
3. Replace `your_groq_api_key_here` with your actual Groq API key.

Make sure to add `.env` to your `.gitignore` file to keep your API key secure.

## Database creation

Provide instructions for creating the database.

## Database initialization

Explain how to initialize the database with necessary data.

## How to run the test suite

Describe the process for running the test suite.

## Services (job queues, cache servers, search engines, etc.)

List any services the application depends on and how to set them up.

## Deployment instructions

Provide instructions for deploying the application.

## Additional Information

Add any additional information that might be helpful for users or developers working with this project.

## Dev Log
** Friday Oct 18, 2024 **
I've got everything wired together but results are not consistent. Sometimes the LLM makes
stuff up about putting it into the oven. I've been testing with this link: [gluten free naan](https://theloopywhisk.com/2023/03/05/easy-gluten-free-naan-bread/#wprm-recipe-container-15391)

Sometimes it comes back intelligable but often it does not. I can't tell why yet. It seems like the scraper results are not consistent. Is that why?

** Saturday Oct 19, 2024 **
Tried switching to the text/event-stream option provided by Jina. This seems more consistent but it's harder to parse the response. Does it use more tokens from Jina as well? Results between their website version and what I'm getting locally are also slightly different.