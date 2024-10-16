#!/bin/bash

# Define the PSQL command to interact with the PostgreSQL database
PSQL="psql --username=postgres --dbname=number_guess -t --no-align -c"

# Prompt the user for their username
echo "Enter your username:"
read USERNAME

# Check if the username exists in the database and retrieve games_played and best_game
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")

# Check if the result is empty or not (new user or returning user)
if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user into the database
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME');"
else
  # Existing user, split the result to get games_played and best_game
  IFS='|' read GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  
  # Handle the case if best_game is null (new user with no best_game yet)
  if [[ -z $BEST_GAME ]]; then
    BEST_GAME="N/A"
  fi
  
  # Print the welcome message for returning user
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESSES=0

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"

while [[ true ]]; do
  read GUESS
  ((GUESSES++))

  # Check if the input is a valid integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Compare the guess with the secret number
  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Update the user's game stats in the database
if [[ $BEST_GAME == "N/A" || $GUESSES -lt $BEST_GAME ]]; then
  $PSQL "UPDATE users SET best_game=$GUESSES WHERE username='$USERNAME';"
fi
$PSQL "UPDATE users SET games_played=games_played+1 WHERE username='$USERNAME';"
