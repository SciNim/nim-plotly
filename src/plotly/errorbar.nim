import chroma

# plotly internal modules
import plotly_types
import color

# this module contains all procedures related to the `ErrorBar` class
# e.g. convenience functions to create a new `ErrorBar` object

func newErrorBar*[T: SomeNumber](err: T, color: Color = empty(), thickness = 0.0,
                                 width = 0.0, visible = true, percent = false):
                                   ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkConstantSym` or `ebkPercentSym`, if the `percent` flag
  ## is set to `true`
  # NOTE: there is a lot of visual noise in the creation here... change how?
  if percent == false:
    result = ErrorBar[T](visible: visible, color: color, thickness: thickness,
                         width: width, kind: ebkConstantSym)
    result.value = err
  else:
    result = ErrorBar[T](visible: visible, color: color, thickness: thickness,
                         width: width, kind: ebkPercentSym)
    result.percent = err

func newErrorBar*[T: SomeNumber](err: tuple[m, p: T], color: Color = empty(),
                                 thickness = 0.0, width = 0.0, visible = true,
                                 percent = false): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkConstantAsym`, constant plus and
  ## minus errors given as tuple or `ebkPercentAsym` of `percent` flag is set to true
  ## Note: the first element of the `err` tuple is the `negative` size, the second
  ## the positive!
  if percent == false:
    result = ErrorBar[T](visible: visible, color: color, thickness: thickness,
                         width: width, kind: ebkConstantAsym)
    result.valuePlus  = err.p
    result.valueMinus = err.m
  else:
    result = ErrorBar[T](visible: visible, color: color, thickness: thickness,
                         width: width, kind: ebkPercentAsym)
    result.percentPlus  = err.p
    result.percentMinus = err.m

func newErrorBar*[T: SomeNumber](color: Color = empty(), thickness = 0.0,
                                 width = 0.0, visible = true): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkSqrt`
  result = ErrorBar[T](visible: visible, color: color, thickness: thickness,
                       width: width, kind: ebkSqrt)

func newErrorBar*[T](err: seq[T], color: Color = empty(), thickness = 0.0,
                     width = 0.0, visible = true): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkArraySym`
  result = ErrorBar[T](visible: visible, color: color, thickness: thickness,
                       width: width, kind: ebkArraySym)
  result.errors = err

func newErrorBar*[T: SomeNumber](err: tuple[m, p: seq[T]], color: Color = empty(),
                                 thickness = 0.0, width = 0.0, visible = true): ErrorBar[T] =
  ## creates an `ErrorBar` object of type `ebkArrayAsym`, where the first
  ## Note: the first seq of the `err` tuple is the `negative` error seq, the second
  ## the positive!
  result = ErrorBar[T](visible: visible, color: color, thickness: thickness,
                       width: width, kind: ebkArrayAsym)
  result.errorsPlus  = err.p
  result.errorsMinus = err.m
