{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE OverloadedStrings  #-}
-----------------------------------------------------------------------------
-- |
-- License     :  BSD-3-Clause
-- Maintainer  :  Oleg Grenrus <oleg.grenrus@iki.fi>
--
module GitHub.Data.Repos where

import Prelude        ()
import Prelude.Compat

import GitHub.Data.Definitions
import GitHub.Data.Id          (Id)
import GitHub.Data.Name        (Name)

import Control.DeepSeq          (NFData (..))
import Control.DeepSeq.Generics (genericRnf)
import Data.Aeson.Compat        (FromJSON (..), ToJSON (..), object, withObject,
                                 (.:), (.:?), (.=))
import Data.Binary              (Binary)
import Data.Data                (Data, Typeable)
import Data.Text                (Text)
import Data.Time                (UTCTime)
import Data.Vector              (Vector)
import GHC.Generics             (Generic)

import qualified Data.HashMap.Strict as HM
import qualified Data.Vector         as V

data Repo = Repo {
   repoSshUrl          :: !(Maybe Text)
  ,repoDescription     :: !(Maybe Text)
  ,repoCreatedAt       :: !(Maybe UTCTime)
  ,repoHtmlUrl         :: !Text
  ,repoSvnUrl          :: !(Maybe Text)
  ,repoForks           :: !(Maybe Int)
  ,repoHomepage        :: !(Maybe Text)
  ,repoFork            :: !(Maybe Bool)
  ,repoGitUrl          :: !(Maybe Text)
  ,repoPrivate         :: !Bool
  ,repoCloneUrl        :: !(Maybe Text)
  ,repoSize            :: !(Maybe Int)
  ,repoUpdatedAt       :: !(Maybe UTCTime)
  ,repoWatchers        :: !(Maybe Int)
  ,repoOwner           :: !SimpleOwner
  ,repoName            :: !(Name Repo)
  ,repoLanguage        :: !(Maybe Text)
  ,repoMasterBranch    :: !(Maybe Text)
  ,repoPushedAt        :: !(Maybe UTCTime)   -- ^ this is Nothing for new repositories
  ,repoId              :: !(Id Repo)
  ,repoUrl             :: !Text
  ,repoOpenIssues      :: !(Maybe Int)
  ,repoHasWiki         :: !(Maybe Bool)
  ,repoHasIssues       :: !(Maybe Bool)
  ,repoHasDownloads    :: !(Maybe Bool)
  ,repoParent          :: !(Maybe RepoRef)
  ,repoSource          :: !(Maybe RepoRef)
  ,repoHooksUrl        :: !Text
  ,repoStargazersCount :: !Int
} deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData Repo where rnf = genericRnf
instance Binary Repo

data RepoRef = RepoRef
    { repoRefOwner :: !SimpleOwner
    , repoRefRepo  :: !(Name Repo)
    }
    deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData RepoRef where rnf = genericRnf
instance Binary RepoRef

data NewRepo = NewRepo {
  newRepoName        :: !(Name Repo)
, newRepoDescription :: !(Maybe Text)
, newRepoHomepage    :: !(Maybe Text)
, newRepoPrivate     :: !(Maybe Bool)
, newRepoHasIssues   :: !(Maybe Bool)
, newRepoHasWiki     :: !(Maybe Bool)
, newRepoAutoInit    :: !(Maybe Bool)
} deriving (Eq, Ord, Show, Data, Typeable, Generic)

instance NFData NewRepo where rnf = genericRnf
instance Binary NewRepo

newRepo :: Name Repo -> NewRepo
newRepo name = NewRepo name Nothing Nothing Nothing Nothing Nothing Nothing

data EditRepo = EditRepo {
  editName         :: !(Maybe (Name Repo))
, editDescription  :: !(Maybe Text)
, editHomepage     :: !(Maybe Text)
, editPublic       :: !(Maybe Bool)
, editHasIssues    :: !(Maybe Bool)
, editHasWiki      :: !(Maybe Bool)
, editHasDownloads :: !(Maybe Bool)
} deriving (Eq, Ord, Show, Data, Typeable, Generic)

instance NFData EditRepo where rnf = genericRnf
instance Binary EditRepo

-- | Filter the list of the user's repos using any of these constructors.
data RepoPublicity
    = RepoPublicityAll     -- ^ All repos accessible to the user.
    | RepoPublicityOwner   -- ^ Only repos owned by the user.
    | RepoPublicityPublic  -- ^ Only public repos.
    | RepoPublicityPrivate -- ^ Only private repos.
    | RepoPublicityMember  -- ^ Only repos to which the user is a member but not an owner.
    deriving (Show, Eq, Ord, Typeable, Data, Generic)

-- | This is only used for the FromJSON instance.
data Languages = Languages { getLanguages :: Vector Language }
  deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData Languages where rnf = genericRnf
instance Binary Languages

-- | A programming language with the name and number of characters written in
-- it.
data Language = Language !Text !Int
 deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData Language where rnf = genericRnf
instance Binary Language

data Contributor
  -- | An existing Github user, with their number of contributions, avatar
  -- URL, login, URL, ID, and Gravatar ID.
  = KnownContributor !Int !Text !(Name User) !Text !(Id User) !Text
  -- | An unknown Github user with their number of contributions and recorded name.
  | AnonymousContributor !Int !Text
 deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData Contributor where rnf = genericRnf
instance Binary Contributor

contributorToSimpleUser :: Contributor -> Maybe SimpleUser
contributorToSimpleUser (AnonymousContributor _ _) = Nothing
contributorToSimpleUser (KnownContributor _contributions avatarUrl name url uid _gravatarid) =
    Just $ SimpleUser uid name avatarUrl url OwnerUser

-- JSON instances

instance FromJSON Repo where
  parseJSON = withObject "Repo" $ \o ->
    Repo <$> o .:? "ssh_url"
         <*> o .: "description"
         <*> o .:? "created_at"
         <*> o .: "html_url"
         <*> o .:? "svn_url"
         <*> o .:? "forks"
         <*> o .:? "homepage"
         <*> o .: "fork"
         <*> o .:? "git_url"
         <*> o .: "private"
         <*> o .:? "clone_url"
         <*> o .:? "size"
         <*> o .:? "updated_at"
         <*> o .:? "watchers"
         <*> o .: "owner"
         <*> o .: "name"
         <*> o .:? "language"
         <*> o .:? "master_branch"
         <*> o .:? "pushed_at"
         <*> o .: "id"
         <*> o .: "url"
         <*> o .:? "open_issues"
         <*> o .:? "has_wiki"
         <*> o .:? "has_issues"
         <*> o .:? "has_downloads"
         <*> o .:? "parent"
         <*> o .:? "source"
         <*> o .: "hooks_url"
         <*> o .: "stargazers_count"

instance ToJSON NewRepo where
  toJSON (NewRepo { newRepoName         = name
                  , newRepoDescription  = description
                  , newRepoHomepage     = homepage
                  , newRepoPrivate      = private
                  , newRepoHasIssues    = hasIssues
                  , newRepoHasWiki      = hasWiki
                  , newRepoAutoInit     = autoInit
                  }) = object
                  [ "name"                .= name
                  , "description"         .= description
                  , "homepage"            .= homepage
                  , "private"             .= private
                  , "has_issues"          .= hasIssues
                  , "has_wiki"            .= hasWiki
                  , "auto_init"           .= autoInit
                  ]

instance ToJSON EditRepo where
  toJSON (EditRepo { editName         = name
                   , editDescription  = description
                   , editHomepage     = homepage
                   , editPublic       = public
                   , editHasIssues    = hasIssues
                   , editHasWiki      = hasWiki
                   , editHasDownloads = hasDownloads
                   }) = object
                   [ "name"          .= name
                   , "description"   .= description
                   , "homepage"      .= homepage
                   , "public"        .= public
                   , "has_issues"    .= hasIssues
                   , "has_wiki"      .= hasWiki
                   , "has_downloads" .= hasDownloads
                   ]

instance FromJSON RepoRef where
  parseJSON = withObject "RepoRef" $ \o ->
    RepoRef <$> o .: "owner"
            <*> o .: "name"

instance FromJSON Contributor where
    parseJSON = withObject "Contributor" $ \o -> do
        t <- o .: "type"
        case t of
            _ | t == ("Anonymous" :: Text) ->
                AnonymousContributor
                    <$> o .: "contributions"
                    <*> o .: "name"
            _ | otherwise ->
                KnownContributor
                    <$> o .: "contributions"
                    <*> o .: "avatar_url"
                    <*> o .: "login"
                    <*> o .: "url"
                    <*> o .: "id"
                    <*> o .: "gravatar_id"

instance FromJSON Languages where
  parseJSON = withObject "Languages" $ \o ->
    Languages . V.fromList <$>
      traverse (\name -> Language name <$> o .: name)
           (HM.keys o)