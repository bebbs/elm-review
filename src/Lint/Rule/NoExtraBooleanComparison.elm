module Lint.Rule.NoExtraBooleanComparison exposing (rule)

{-|

@docs rule


# Fail

    if Debug.log "condition" condition then
        a

    else
        b

    if condition then
        Debug.crash "Nooo!"

    else
        value


# Success

    if condition then
        a

    else
        b

-}

import Elm.Syntax.Expression as Expression exposing (Expression(..))
import Elm.Syntax.Node as Node exposing (Node)
import Lint.Rule as Rule exposing (Error, Rule)


{-| Forbid the use of `Debug` before it goes into production.

    config =
        [ ( Critical, NoExtraBooleanComparison.rule )
        ]

-}
rule : Rule
rule =
    Rule.newSchema "NoExtraBooleanComparison"
        |> Rule.withSimpleExpressionVisitor expressionVisitor
        |> Rule.fromSchema


error : Node a -> String -> Error
error node comparedValue =
    Rule.error
        ("Unnecessary comparison with `" ++ comparedValue ++ "`")
        (Node.range node)


expressionVisitor : Node Expression -> List Error
expressionVisitor node =
    case Node.value node of
        Expression.OperatorApplication operator _ left right ->
            if isEqualityOperator operator then
                List.filterMap isTrueOrFalse [ left, right ]
                    |> List.map (error node)

            else
                []

        _ ->
            []


isEqualityOperator : String -> Bool
isEqualityOperator operator =
    operator == "==" || operator == "/="


isTrueOrFalse : Node Expression -> Maybe String
isTrueOrFalse node =
    case Node.value node of
        FunctionOrValue [] functionOrValue ->
            if functionOrValue == "True" || functionOrValue == "False" then
                Just functionOrValue

            else
                Nothing

        _ ->
            Nothing