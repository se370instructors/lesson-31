#-SE370 Lesson 31: Text Analysis II
#-By: Ian Kloo
#-April 2022

library(dplyr)
library(tidytext)
library(ggplot2)
library(tidyr)
library(readr)
library(topicmodels)
library(wordcloud)

#this file includes code demonstrating basic text analysis techniques including:
#1. Term Frequency Analysis
#2. TF/IDF Analysis
#3. Plotting with ggplot bars and wordclouds
#4. Sentiment analysis
#5. Topic modeling



#---Tidy Text - Recall Word Frequency Analysis---#
#we will use a dataset containing "real" and "fake" political news
news <- read_csv('news_sample.csv')
head(news)

#lets replace the titles with IDs to simplify things:
news_df <- news %>%
  mutate(id = 1:nrow(news)) %>%
  select(id, text, reliable)

head(news_df)

#now we tokenize the text, remove stopwords, count the words, and take the top 20
top_words <- news_df %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(word) %>%
  arrange(-n) %>%
  slice(1:20)

ggplot(top_words, aes(x = n, y = reorder(word, n))) + geom_bar(stat = 'identity') + theme_minimal()
#clear political commentary with a lot of discussion of elections and trump in particular.


#do the reliable and unreliable sources look any different?
#we can do the same thing, taking the top 20 words for each category (reliable, not reliable)
top_words <- news_df %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  group_by(id, word, reliable) %>%
  summarize(n = n()) %>%
  group_by(reliable) %>%
  slice_max(n, n = 20)

ggplot(top_words, aes(x = n, y = reorder(word, n))) + geom_bar(stat = 'identity') + theme_minimal() +
  facet_wrap(~reliable)
#it looks like reliable sources are more focused on policy issues and foreign policy than the unreliable sources.


#-wordclouds are another useful way to show word frequency.  
#just be careful - word size is not an efficient visual channel...but it gets the point across in some circumstances

#the data looks the same as above, but we don't have to subset to the top 20 words
wc_data <-  news_df %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(word) %>%
  arrange(-n) 

wordcloud(words = wc_data$word, freq = wc_data$n, min.freq = 20, max.words = 100,
          random.order = FALSE, rot.per = .35, colors = brewer.pal(8, 'Dark2'))
#tinker with the parameters to get different looking word clouds, but these are a popular set of parameters





#---Beyond Frequency: TF/IDF---#
#but is word frequency really meaningful?  it's complicated...
#maybe how rare a word is should be conisdered as well...

#here we explore TF (term frequency) and IDF (inverse document frequency = inverse of number of documents containing a word)
#TF is just a count so it catches a lot of commonly used words, but they aren't good at distinguishing texts
#IDF is a measure of how rare a document is in a set of documents (called a corpus)
#TF/IDF is a combined metric that is often used to find "important" words

#first count the number of times each word appears in each article
article_counts <- news_df %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(id, word)

#now count the number of words in each article
total_counts <- article_counts %>%
  group_by(id) %>%
  summarize(total = sum(n))

#join them back up
article_words <- article_counts %>%
  left_join(total_counts)

#now we have columns for: the article ID, a word used in the article, the number of times it was used, and the total number of words in the article
article_words

#tidytext includes a function to find the TF, IDF, and TF/IDF for each word
news_tf_idf <- article_words %>%
  bind_tf_idf(word, id, n) 

news_tf_idf %>%
  arrange(-tf_idf)

news_tf_idf %>%
  arrange(-tf)

news_tf_idf %>%
  arrange(-idf)

#subsetting down to the top 25 by TF/IDF
plot_data <- news_tf_idf %>%
  arrange(-tf_idf) %>%
  slice(1:25)

ggplot(plot_data, aes(x = tf_idf, y = reorder(word, tf_idf))) + geom_bar(stat = 'identity') + theme_minimal()
#here we get away from the very common words (e.g., presedent) and into some potentially more usefully descriptive words

#almost all of modern text analytics uses TF/IDF instead of simple TF





#---Sentiment Analysis---#
#lets go beyond just figuring out what the articles are about and think about the sentiment expressed in them
#ex) can we separate "positive" from "negative" articles?
#sentiment analysis typically relies on dictionaries of words tagged with different sentiments called lexicons
#afinn is a popular lexicon that provides a numeric value

#*you might have to type "y" after running the next line - only the first time you run it.*#
get_sentiments("afinn")

#lets get back to our uncounted data with words and article IDs only
article_counts <- news_df %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words)

#now we can inner join the afinn data to find the sentiment value of each word
article_sentiment <- article_counts %>%
  inner_join(get_sentiments("afinn"))

article_sentiment

#now we can add up the sentiments by article
news_sentiment <- article_sentiment %>%
  group_by(id) %>%
  summarize(sentiment = sum(value))

#and we can see the most negative and positive articles
news_sentiment %>%
  arrange(-sentiment)

#lets look at the most positive
news_df$text[news_df$id == 248]
#I wouldn't exactly say this is a "positive" news article, but it doesn't use a huge amount of negative language until the end

news_sentiment %>%
  arrange(sentiment)

#and the most negative
news_df$text[news_df$id == 17]
#this one get right into very inflammatory words right away.

#lets look at the overall sentiment of our news data
ggplot(news_sentiment, aes(x = sentiment)) +
  geom_density() + theme_minimal()
#these articles are mostly using negative terms.  that makes sense, politics is not a friendly business.


#is there a different distribution of sentiment for reliable vs. unreliable news?:
news_sentiment_reliable <- article_sentiment %>%
  group_by(id, reliable) %>%
  summarize(sentiment = sum(value))

ggplot(news_sentiment_reliable, aes(x = sentiment)) +
  geom_density() + facet_wrap(~reliable, ncol = 1) + theme_minimal()
#maybe not the easiest visualization to compare these curves...

#show the mean sentiment for each category
news_sentiment_reliable %>%
  group_by(reliable) %>%
  summarize(avg = mean(sentiment))

#maybe a nicer way to visualize (though a bit messy to create)
ggplot() +
  geom_density(data = news_sentiment_reliable[news_sentiment_reliable$reliable == 1,], aes(x = sentiment, fill = 'Reliable'), color = NA,  alpha = .5) + 
  geom_density(data = news_sentiment_reliable[news_sentiment_reliable$reliable == 0,], aes(x = sentiment, fill = 'Unreliable'), color = NA, alpha = .5) +
  theme_minimal() + scale_fill_manual(name = "", values = c("Reliable" = "purple", "Unreliable" = "orange"))

#there appears to be a difference here.  the unreliable sources tend to use more negative words.  that also makes sense.

#sentiment analysis is a powerful tool, but it isn't perfect.  consider issues with sarcasm, slang, and strange "internet language".





#---Topic Modeling---#
#a final tool we'll cover is topic modeling.  this is a complicated subject, so we'll just scratch the surface.
#the general idea is to try to learn a set of topics in your data.  we can use these topics to understand what the 
#articles are talking about and potentially bin our articles into distinct topics.

#we first need to rework our data into what is called a document-term matrix
#the matrix has a row for each document and a column for each word used in ANY of the documents.
#the cells show the number of times a word was used in a document.
article_counts <- news_df %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(id, word) %>%
  cast_dtm(id, word, n)

#now we can apply LDA = latent dirichlet allocation 
#we have to pick a number of documents we think exist in the data...
#...you can use analytic methods to optimize this number...outside of our scope
news_topics <- LDA(article_counts, k = 3)

#now we can extract the top 5 terms for each topic
tidy(news_topics, matrix = 'beta') %>%
  group_by(topic) %>%
  slice_max(beta, n = 5) %>%
  arrange(topic, -beta)
#because the topics are machine-learned, the best we can get for a description of each topic is 
#a list of words that appear regularly in each topic.

#these look to be pretty similar topics.  maybe one is about just Trump, one is about Trump vs. Clinton, and
#one is about more general policy?  It is open to interpretation.

#finally, we can extract the top 5 documents for each topic
tidy(news_topics, matrix = "gamma") %>%
  group_by(topic) %>%
  slice_max(gamma, n = 5) %>%
  arrange(topic, -gamma)

#lets look at a few of the documents to see if they fit
news_df[141,]
news_df[148,]
news_df[164,]





