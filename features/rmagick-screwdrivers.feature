Feature: Handy utilities for processing images
  In order to make RMagick kinda command-line utility
  We want to provide some handy utility methods

  Scenario: folder of images may be processed to make a collage
    Given a folder "data/images" is given as the input
    And an output folder "data/results" is created
    When I call the collage method
    And save file to "data/results/collage.jpg"
    Then the result is created as "data/results/collage.jpg"

  Scenario: image scaling with optional watermark
    Given an image "data/images/DSCF1354.JPG" is given as the input
    And an output folder "data/results" is created
    And everything is logged
    When I call the scale method with widths 800,600,150
    And save files with origin "data/results/scaled"
    Then the result is created as an array of size 3

  Scenario: create standard demotivator from image
    Given an image "data/images/DSCF1354.JPG" is given as the input
    And "standard" is given as poster type option 
    And an output folder "data/results" is created
    And everything is logged
    When I call the poster method with texts "Hello, there" and "I’m a demotivator"
    And save file to "data/results/demotivator-standard.jpg"
    Then the result is created as "data/results/demotivator-standard.jpg"

  Scenario: create classic demotivator from image
    Given an image "data/images/DSCF1354.JPG" is given as the input
    And "classic" is given as poster type option 
    And an output folder "data/results" is created
    And everything is logged
    When I call the poster method with texts "Hello, there" and "I’m a demotivator"
    And save file to "data/results/demotivator-classic.jpg"
    Then the result is created as "data/results/demotivator-classic.jpg"

  Scenario: create negative demotivator from image
    Given an image "data/images/DSCF1354.JPG" is given as the input
    And "negative" is given as poster type option 
    And an output folder "data/results" is created
    And everything is logged
    When I call the poster method with texts "Hello, there" and "I’m a demotivator"
    And save file to "data/results/demotivator-negative.jpg"
    Then the result is created as "data/results/demotivator-negative.jpg"


