{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Domain.Repository.DogRepository where

import Data.Aeson
import Data.Text (Text)
import Database.MySQL.Base
import Database.MySQL.Protocol.MySQLValue
import Domain.Entity.Dog
import GHC.Generics
import GHC.Word
import Text.Read (readMaybe)
import qualified System.IO.Streams as Streams

data CreateDogDto = CreateDogDto {
  cdName :: Text
, cdBread :: Text
, cdOwnerId :: Int
} deriving (Show, Generic)

instance FromJSON CreateDogDto

createEntity :: [MySQLValue] -> Maybe Dog
createEntity (MySQLInt32 did : MySQLText name : MySQLText bread : MySQLInt32 ownerId : MySQLText ownerName : _) = 
  Just Dog {
    did = readMaybe $ show did
  , name
  , bread
  , ownerId = read $ show ownerId
  , ownerName
  }
createEntity _ = Nothing

findDogById :: Int -> MySQLConn -> IO [Maybe Dog]
findDogById did conn = do
  s <- prepareStmt conn "SELECT dogs.id, dogs.name, dogs.bread, users.id, users.name from dogs inner join users on dogs.owner_id = users.id where dogs.id = ?"
  (defs, is) <- queryStmt conn s [MySQLInt32U $ fromIntegral did]
  map createEntity <$> Streams.toList is

createDog :: CreateDogDto -> MySQLConn -> IO(OK)
createDog dog conn = do
  s <- prepareStmt conn "INSERT INTO dogs (name, bread, owner_id) values (?, ?, ?)"
  executeStmt conn s [MySQLText $ cdName dog, MySQLText $ cdBread dog, MySQLInt32 $ fromIntegral $ cdOwnerId dog]

findAllDog :: MySQLConn -> IO [Maybe Dog]
findAllDog conn = do
  s <- prepareStmt conn "SELECT dogs.id, dogs.name, dogs.bread, users.id, users.name from dogs inner join users on dogs.owner_id = users.id"
  (defs, is) <- queryStmt conn s []
  map createEntity <$> Streams.toList is
