/***************************************************************************************************
* Class Name   : BooleanExpressionTest
* Created Date : July 4, 2018
* Author       : Vijaya Sankar N
* Description  : Class to evaluate a boolean expression 
* Example      : (TRUE AND (FALSE OR TRUE)) is TRUE
****************************************************************************************************/
@isTest
public with sharing class BooleanExpressionTest {

    public static testmethod void eval_test() {
        System.assert(BooleanExpression.eval('TRUE'));
        System.assert(BooleanExpression.eval('TRUE OR FALSE'));
        System.assert(BooleanExpression.eval('TRUE OR TRUE'));
        System.assert(BooleanExpression.eval('TRUE OR (TRUE AND FALSE)'));
        System.assert(BooleanExpression.eval('TRUE OR (TRUE AND FALSE AND TRUE OR TRUE)'));
        System.assert(BooleanExpression.eval('TRUE OR (TRUE AND FALSE AND (TRUE OR FALSE))'));
        System.assert(BooleanExpression.eval('TRUE OR (TRUE OR (FALSE AND (TRUE OR FALSE)))'));
        System.assert(BooleanExpression.eval('(FALSE OR ((TRUE OR FALSE) AND (TRUE OR FALSE)))'));
		System.assert(BooleanExpression.eval('((FALSE OR TRUE OR FALSE) AND (FALSE OR TRUE OR FALSE) AND TRUE) OR FALSE'));
		System.assert(BooleanExpression.eval('(TRUE AND TRUE AND TRUE) OR ((FALSE OR TRUE) AND TRUE AND TRUE AND TRUE) OR (FALSE AND FALSE)'));
		System.assert(BooleanExpression.eval('(TRUE AND FALSE AND FALSE) OR ((FALSE OR TRUE) AND TRUE AND FALSE AND TRUE) OR (TRUE AND TRUE)'));
		System.assert(BooleanExpression.eval('((TRUE OR FALSE) AND (FALSE OR FALSE OR TRUE)) OR ((FALSE OR FALSE) AND FALSE AND FALSE) OR (FALSE AND TRUE) OR (TRUE AND FALSE) OR (FALSE OR FALSE)'));
		System.assert(BooleanExpression.eval('((FALSE OR FALSE) AND (FALSE OR FALSE OR FALSE)) OR ((TRUE OR FALSE) AND TRUE AND TRUE) OR (FALSE AND TRUE) OR (TRUE AND FALSE) OR (FALSE OR FALSE)'));
		System.assert(BooleanExpression.eval('((FALSE OR FALSE) AND (FALSE OR FALSE OR FALSE)) OR ((FALSE OR FALSE) AND FALSE AND FALSE) OR (TRUE AND TRUE) OR (TRUE AND FALSE) OR (FALSE OR FALSE)'));
		System.assert(BooleanExpression.eval('((FALSE OR FALSE) AND (FALSE OR FALSE OR FALSE)) OR ((FALSE OR FALSE) AND FALSE AND FALSE) OR (FALSE AND FALSE) OR (FALSE AND FALSE) OR (TRUE OR FALSE)'));		
        
        System.assert(!BooleanExpression.eval(null));
        System.assert(!BooleanExpression.eval(''));
        System.assert(!BooleanExpression.eval('FALSE'));
        System.assert(!BooleanExpression.eval('TRUE AND FALSE'));
        System.assert(!BooleanExpression.eval('FALSE AND FALSE'));
        System.assert(!BooleanExpression.eval('TRUE AND (TRUE AND FALSE)'));
        System.assert(!BooleanExpression.eval('FALSE AND (TRUE AND FALSE AND TRUE OR TRUE)'));
        System.assert(!BooleanExpression.eval('TRUE AND (TRUE AND FALSE AND (TRUE OR FALSE))'));
        System.assert(!BooleanExpression.eval('TRUE AND (TRUE AND (FALSE AND (TRUE OR FALSE)))'));
        System.assert(!BooleanExpression.eval('(FALSE AND ((TRUE OR FALSE) AND (TRUE OR FALSE)))'));
        System.assert(!BooleanExpression.eval('((FALSE OR TRUE OR TRUE) AND (FALSE OR TRUE OR FALSE) AND FALSE) OR FALSE'));
		System.assert(!BooleanExpression.eval('(TRUE AND FALSE AND TRUE) OR ((FALSE OR FALSE) AND TRUE AND FALSE AND TRUE) OR (FALSE AND FALSE)'));
		System.assert(!BooleanExpression.eval('(FALSE AND FALSE AND FALSE) OR ((FALSE OR FALSE) AND FALSE AND FALSE AND TRUE) OR (FALSE AND FALSE)'));
		System.assert(!BooleanExpression.eval('((TRUE OR FALSE) AND (FALSE OR FALSE OR FALSE)) OR ((FALSE OR FALSE) AND FALSE AND FALSE) OR (FALSE AND TRUE) OR (TRUE AND FALSE) OR (FALSE OR FALSE)'));
		System.assert(!BooleanExpression.eval('((FALSE OR FALSE) AND (FALSE OR FALSE OR FALSE)) OR ((TRUE OR FALSE) AND FALSE AND TRUE) OR (FALSE AND TRUE) OR (TRUE AND FALSE) OR (FALSE OR FALSE)'));
		System.assert(!BooleanExpression.eval('((FALSE OR FALSE) AND (FALSE OR FALSE OR FALSE)) OR ((FALSE OR FALSE) AND FALSE AND FALSE) OR (FALSE AND TRUE) OR (TRUE AND FALSE) OR (FALSE OR FALSE)'));
		System.assert(!BooleanExpression.eval('((FALSE OR FALSE) AND (FALSE OR FALSE OR FALSE)) OR ((FALSE OR FALSE) AND FALSE AND FALSE) OR (FALSE AND FALSE) OR (FALSE AND FALSE) OR (FALSE OR FALSE)'));
    }


}