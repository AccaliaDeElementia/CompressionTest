# CompressionTest
Let's test some compression utilities!

## Rationale

It is a perennial argument on the internet, just what is the best compressor to use to losslessly compress data, Yet no one tries to actually test the utilities against multiple types of input data. So I decided to do just that. 

These compression tests are performed using PowerShell to script the tests and are automatically run using appveyor, allowing new utilities or test corpuses to be tested and reported automatically.

## Test Corpuses
To perform the tests several different test corpuses are required to stress the utilities in different ways. The following are the test corpuses used in these tests

### English Text Corpus
This corpus contains Public domain books provided by Project Gutenberg. These books were chosen to create a test corpus of approximately 10 megabytes that incorporates several dramatically different writing styles.

The following is a list of books used for these tests:

[The King James Bible](http://www.gutenberg.org/ebooks/10)<br />
[The Koran (Al-Qur'an) as translated by G. Margoliuth and J. M. Rodwell](http://www.gutenberg.org/ebooks/2800)<br />
[The Adventures of Tom Sawyer by Mark Twain](https://www.gutenberg.org/ebooks/74)<br />
[Pride and Prejudice by Jane Austin](https://www.gutenberg.org/ebooks/1342)<br />
[Dracula by Bram Stoker](https://www.gutenberg.org/ebooks/345)<br />
[War and Peace by graf Leo Tolstoy](https://www.gutenberg.org/ebooks/2600)<br />
[Beowulf](https://www.gutenberg.org/ebooks/16328)<br />
[Metamorphosis by Franz Kafka](https://www.gutenberg.org/ebooks/5200)<br />

### Random Binary Data Corpus
This corpus is created as a single 10 megabyte file of pseudorandom binary data. This test was created to test the compression utilities in a "worst case" scenario of compressing completely random data.

### Random ASCII Data Corpus
This corpus is created as a single 10 megabyte file of pseudorandom ASCII data. This test was created to test the compression utilities in a "worst case" scenario of compressing completely random data.

### jQuery Corpus
This corpus is composed of a fresh checkout of the current source code for the popular javascript library. It was chosen as an example of a large repository of computer source code in order to test how the utilities handle somewhat structured data.

<script type="text/javascript">
    console.log('testing scripts in gh pages using markdown')
</script>