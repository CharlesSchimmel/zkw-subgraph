module MdGraph.Parse
    ( parseDocument
    , ParseResult(..)
    ) where

import           MdGraph.Node
import           MdGraph.Parse.Pandoc

import           Control.Concurrent.Async       ( mapConcurrently )
import           Data.Either                    ( partitionEithers )
import qualified Data.HashSet                  as S
                                                ( toList )
import           Data.Maybe                     ( fromMaybe )
import           Data.Text                     as T
import           Data.Text.IO                  as T
                                                ( readFile )
import           MdGraph.File                   ( fixLink )
import           Prelude                       as P
import           System.Directory               ( doesFileExist
                                                , getModificationTime
                                                )
import           System.FilePath                ( (</>) )
import           Text.Pandoc                    ( PandocMonad(fileExists) )

data ParseResult = ParseResult
    { file  :: FilePath
    , links :: [Link]
    , tags  :: [Tag]
    }
    deriving Show

-- TODO: mapConcurrently should be used by consumer of these functions

parseDocument :: FilePath -> FilePath -> FilePath -> IO (Maybe ParseResult)
parseDocument defExt libraryPath file = do
    exists <- doesFileExist absFile
    if not exists
        then return Nothing
        else do
            fileContent <- T.readFile file
            return $ do
                PandocResult { tags, links } <- sieveLinks fileContent
                return $ ParseResult file (S.toList links) (S.toList tags)
  where
    absFile = libraryPath </> file
    parseFile :: FilePath -> IO PandocResult
    parseFile file = do
        content <- sieveLinks <$> T.readFile file
        return $ fromMaybe mempty content

