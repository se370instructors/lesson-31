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


#now we tokenize the text, remove stopwords, count the words, and take the top 20


#do the reliable and unreliable sources look any different?
#we can do the same thing, taking the top 20 words for each category (reliable, not reliable)


#-wordclouds are another useful way to show word frequency.  
#just be careful - word size is not an efficient visual channel...but it gets the point across in some circumstances

#the data looks the same as above, but we don't have to subset to the top 20 words




#---Beyond Frequency: TF/IDF---#
#but is word frequency really meaningful?  it's complicated...
#maybe how rare a word is should be conisdered as well...

#here we explore TF (term frequency) and IDF (inverse document frequency = inverse of number of documents containing a word)
#TF is just a count so it catches a lot of commonly used words, but they aren't good at distinguishing texts
#IDF is a measure of how rare a document is in a set of documents (called a corpus)
#TF/IDF is a combined metric that is often used to find "important" words

#first count the number of times each word appears in each article

#now count the number of words in each article

#join them back up

#now we have columns for: the article ID, a word used in the article, the number of times it was used, and the total number of words in the article

#tidytext includes a function to find the TF, IDF, and TF/IDF for each word

#subsetting down to the top 25 by TF/IDF





#---Sentiment Analysis---#
#lets go beyond just figuring out what the articles are about and think about the sentiment expressed in them
#ex) can we separate "positive" from "negative" articles?
#sentiment analysis typically relies on dictionaries of words tagged with different sentiments called lexicons
#afinn is a popular lexicon that provides a numeric value

#*you might have to type "y" after running the next line - only the first time you run it.*#

#lets get back to our uncounted data with words and article IDs only

#now we can inner join the afinn data to find the sentiment value of each word

#now we can add up the sentiments by article

#and we can see the most negative and positive articles

#lets look at the most positive

#and the most negative

#lets look at the overall sentiment of our news data


#is there a different distribution of sentiment for reliable vs. unreliable news?:

#show the mean sentiment for each category

#maybe a nicer way to visualize (though a bit messy to create)




#---Topic Modeling---#
#a final tool we'll cover is topic modeling.  this is a complicated subject, so we'll just scratch the surface.
#the general idea is to try to learn a set of topics in your data.  we can use these topics to understand what the 
#articles are talking about and potentially bin our articles into distinct topics.

#we first need to rework our data into what is called a document-term matrix
#the matrix has a row for each document and a column for each word used in ANY of the documents.
#the cells show the number of times a word was used in a document.


#now we can apply LDA = latent dirichlet allocation 
#we have to pick a number of documents we think exist in the data...
#...you can use analytic methods to optimize this number...outside of our scope


#now we can extract the top 5 terms for each topic


#finally, we can extract the top 5 documents for each topic


#lets look at a few of the documents to see if they fit





