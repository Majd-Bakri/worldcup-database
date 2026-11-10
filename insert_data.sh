#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Clear previous data
$PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY;"

# Read each row from the CSV file
while IFS=',' read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # Skip the header
  if [[ $YEAR == "year" ]]
  then
    continue
  fi

  # Insert teams and game together.
  # Team IDs are obtained from the database.
  RESULT=$($PSQL "
    WITH winner_team AS (
      INSERT INTO teams(name)
      VALUES ('$WINNER')
      ON CONFLICT (name)
      DO UPDATE SET name = EXCLUDED.name
      RETURNING team_id
    ),
    opponent_team AS (
      INSERT INTO teams(name)
      VALUES ('$OPPONENT')
      ON CONFLICT (name)
      DO UPDATE SET name = EXCLUDED.name
      RETURNING team_id
    )
    INSERT INTO games(
      year,
      round,
      winner_id,
      opponent_id,
      winner_goals,
      opponent_goals
    )
    SELECT
      $YEAR,
      '$ROUND',
      winner_team.team_id,
      opponent_team.team_id,
      $WINNER_GOALS,
      $OPPONENT_GOALS
    FROM winner_team, opponent_team;
  ")

  echo "Inserted: $YEAR $ROUND - $WINNER vs $OPPONENT"

done < games.csv
