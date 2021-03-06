module Servis.Dependent.API

import public Data.Vect
import public Data.HVect

%default total
%access public export

interface Universe u where
  el : u -> Type

data Handler : req -> res -> Type where
  GET : (responseType : res) -> Handler req res
  POST : (Universe req, Universe res) => (requestType : req) -> (responseType : res) -> Handler req res

(Universe req, Universe resp) => Universe (Handler req resp) where
  el (GET responseType) = IO (el responseType)
  el (POST requestType responseType) = el requestType -> IO (el responseType)

data PathPart : capture -> query -> Type where
  Const : (path : String) -> PathPart capture query
  Capture : (Universe capture) => (name : String) -> (type : capture) -> PathPart capture query
  QueryParam : (Universe query) => (name : String) -> (type : query) -> PathPart capture query

Universe (PathPart capture query) where
  el (Const path) = ()
  el (Capture name type) = el type
  el (QueryParam name type) = el type

data Path : capture -> query -> req -> res -> Type where
  Outputs : (handler : Handler req res) -> Path capture query req res
  (:>) :  (pathPart : PathPart capture query) -> (path : Path capture query req res) -> Path capture query req res
  -- magic happens here. A dependent pair appears!
  (:*>) : (pathPart : PathPart capture query) -> (path : (el pathPart -> Path capture query req res)) -> Path capture query req res

infixr 5 :>
infixr 5 :*>

( Universe capture
, Universe query
, Universe req
, Universe resp
) => Universe (Path capture query req resp) where
  -- special case because we don't like () in our functions
  el (Const path :> right) =  el right
  el (pathPart :> right) = el pathPart -> el right
  -- special case because we don't like () in our functions
  el (Const path :*> right) = el (right ())
  el (pathPart :*> right) = (k : el pathPart) -> el (right k)
  el (Outputs handler) = el handler

data API : capture -> query -> req -> res -> Type where
  OneOf : (paths : Vect (S n) (Path capture query req res)) -> API capture query req res

( Universe capture
, Universe query
, Universe req
, Universe res
) => Universe (API capture query req res) where
  el (OneOf xs) = HVect (map el xs)

infixr 7 ::

