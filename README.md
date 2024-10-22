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
I've got everything wired together but results are not consistent. Sometimes
the LLM makes stuff up about putting it into the oven. I've been testing with
this link: [gluten free naan](https://theloopywhisk.com/2023/03/05/easy-gluten-free-naan-bread/#wprm-recipe-container-15391)

Sometimes it comes back intelligable but often it does not. I can't tell
why yet. It seems like the scraper results are not consistent. Is that why?

** Saturday Oct 19, 2024 **
Tried switching to the text/event-stream option provided by Jina. This
seems more consistent but it's harder to parse the response. Does it use
more tokens from Jina as well? Results between their website version and
what I'm getting locally are also slightly different.

I'm also going to start saving text scraper results in the database. Maybe
I should do the same with LLM responses? Seems like a little early to
make that optimization.

-----

I have it working more consistently now. With streaming from Jina, I'm saving
the result to a scrapes table and then matching by hostname and request_uri on
follow up requests so we don't have to re-scrape the same site over and over again.
Results from the LLM are still a little inconsistent. I'm not sure how to improve these.
I want to start storing them as related records to the scrape, storing:
- generated text
- model used
- date & time
- response time?
- and maybe a rating?

This way I can test across a few different models to see how they perform.

---

It's not working with deploys. My environment variables weren't loading into kamal secrets
correctly because dotenv wasn't loading them into the environment that kamal was using.
It's a bit confusing to me but I changed it so they get pulled from 1password directly now
which is pretty cool. Formatting is still wierd on the returned results but it works
on the live site now at www.whatistherecipe.org.

This one crashes the site reader: https://smittenkitchen.com/2012/10/chicken-noodle-soup/.
I think because of all the comments. How would I filter that content out?

To try:
- if it fails on the first attempt with 10 second timeout, try again by targetting only the 'article' selector
- or start with the article selector only?
- Try a different webscraper. The website doesn't actually take that long to load. It shouldn't take 15 seconds
or more to retrieve the text of the site. Can I try to do it myself? Or is there another ruby gem available?

** Sunday Oct 20, 2024 **
created a rake task for web scraping using selenium to avoid jina issues. Needs to be moved
to a background job that can be executed on request. From there, need to use turbo streams or
websockets for display updates. Decided on using selenium for now because setting up playwright
requires adding it as a node package to the project which I'd rather avoid for now.

Other ideas:
- run the prompt through multiple models and then have some mechanism for selecting the best result.

** Monday Oct 21, 2024 **
Made significant changes to improve the web scraping and data handling process:

1. Updated `WebScraperService`:
   - Modified `scrape_to_markdown` method to return a Scrape object instead of just the text.
   - This change allows for better data management and easier access to all scrape attributes.

2. Updated rake task in `lib/tasks/scrape_to_markdown.rake`:
   - Modified to handle the new Scrape object returned by `scrape_to_markdown`.
   - Now extracts the text from the Scrape object for output.

3. Updated `SearchController`:
   - Modified `fetch_and_summarize` method to work with the new Scrape object.
   - Improved error handling and data flow.
   - Now creates LlmResponse records only for persisted Scrape objects.

These changes should improve the consistency of scraping results and provide better data management for both scrapes and LLM responses. The next steps could include:
- Implementing background jobs for scraping to improve response times.
- Adding more robust error handling and retry mechanisms.
- Exploring ways to filter out irrelevant content (like comments) from scraped pages.
