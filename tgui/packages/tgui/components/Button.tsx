/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { Placement } from '@popperjs/core';
import { isEscape, KEY } from 'common/keys';
import { BooleanLike, classes } from 'common/react';
import { ChangeEvent, Component, createRef, InfernoMouseEvent } from 'inferno';
import { InfernoReactNode } from '../misc';

import { Box, BoxProps, computeBoxClassName, computeBoxProps } from './Box';
import { Icon } from './Icon';
import { Tooltip } from './Tooltip';

/**
 * Getting ellipses to work requires that you use:
 * 1. A string rather than a node
 * 2. A fixed width here or in a parent
 * 3. Children prop rather than content
 */
type EllipsisUnion =
  | {
      ellipsis: true;
      children: string;
      /** @deprecated use children instead */
      content?: never;
    }
  | Partial<{
      ellipsis: undefined;
      children: InfernoReactNode;
      /** @deprecated use children instead */
      content: InfernoReactNode;
    }>;

type Props = Partial<{
  captureKeys: boolean;
  circular: boolean;
  compact: boolean;
  disabled: BooleanLike;
  fluid: boolean;
  icon: string | false;
  iconColor: string;
  iconPosition: string;
  iconRotation: number;
  iconSpin: BooleanLike;
  onClick: (e: any) => void;
  selected: BooleanLike;
  tooltip: InfernoReactNode;
  tooltipPosition: Placement;
  verticalAlignContent: string;
}> &
  EllipsisUnion &
  BoxProps;

/** Clickable button. Comes with variants. Read more in the documentation. */
export const Button = (props: Props) => {
  const {
    captureKeys = true,
    children,
    circular,
    className,
    color,
    compact,
    content,
    disabled,
    ellipsis,
    fluid,
    icon,
    iconColor,
    iconPosition,
    iconRotation,
    iconSpin,
    onClick,
    selected,
    tooltip,
    tooltipPosition,
    verticalAlignContent,
    ...rest
  } = props;

  const toDisplay: InfernoReactNode | undefined = content || children;

  let buttonContent = (
    <div
      className={classes([
        'Button',
        fluid && 'Button--fluid',
        disabled && 'Button--disabled',
        selected && 'Button--selected',
        !!toDisplay && 'Button--hasContent',
        circular && 'Button--circular',
        compact && 'Button--compact',
        iconPosition && 'Button--iconPosition--' + iconPosition,
        verticalAlignContent && 'Button--flex',
        verticalAlignContent && fluid && 'Button--flex--fluid',
        verticalAlignContent &&
          'Button--verticalAlignContent--' + verticalAlignContent,
        color && typeof color === 'string'
          ? 'Button--color--' + color
          : 'Button--color--default',
        className,
        computeBoxClassName(rest),
      ])}
      tabIndex={!disabled ? 0 : undefined}
      onClick={(event) => {
        if (!disabled && onClick) {
          onClick(event);
        }
      }}
      onKeyDown={(event) => {
        if (!captureKeys) {
          return;
        }

        // Simulate a click when pressing space or enter.
        if (event.key === KEY.Space || event.key === KEY.Enter) {
          event.preventDefault();
          if (!disabled && onClick) {
            onClick(event);
          }
          return;
        }

        // Refocus layout on pressing escape.
        if (isEscape(event.key)) {
          event.preventDefault();
        }
      }}
      {...computeBoxProps(rest)}
    >
      <div className="Button__content">
        {icon && iconPosition !== 'right' && (
          <Icon
            name={icon}
            color={iconColor}
            rotation={iconRotation}
            spin={iconSpin}
          />
        )}
        {!ellipsis ? (
          toDisplay
        ) : (
          <span
            className={classes([
              'Button--ellipsis',
              icon && 'Button__textMargin',
            ])}
          >
            {toDisplay}
          </span>
        )}
        {icon && iconPosition === 'right' && (
          <Icon
            name={icon}
            color={iconColor}
            rotation={iconRotation}
            spin={iconSpin}
          />
        )}
      </div>
    </div>
  );

  if (tooltip) {
    buttonContent = (
      <Tooltip content={tooltip} position={tooltipPosition as Placement}>
        {buttonContent}
      </Tooltip>
    );
  }

  return buttonContent;
};

type CheckProps = Partial<{
  checked: BooleanLike;
}> &
  Props;

/** Visually toggles between checked and unchecked states. */
export const ButtonCheckbox = (props: CheckProps) => {
  const { checked, ...rest } = props;

  return (
    <Button
      color="transparent"
      icon={checked ? 'check-square-o' : 'square-o'}
      selected={checked}
      {...rest}
    />
  );
};

Button.Checkbox = ButtonCheckbox;

type ConfirmProps = Partial<{
  confirmColor: string;
  confirmContent: InfernoReactNode;
  confirmIcon: string;
}> &
  Props;

/**  Requires user confirmation before triggering its action. */

class ButtonConfirm extends Component<ConfirmProps, {clicked: boolean}> {
  state = {
    clicked: false,
  };

  handleClick = (event: InfernoMouseEvent<HTMLDivElement>) => {
    if (!this.state.clicked) {
      this.setClickedOnce(true);
      return;
    }

    this.props.onClick?.(event);
    this.setClickedOnce(false);
    if (this.state.clicked) {
      this.setClickedOnce(false);
    }
  };

  setClickedOnce(clickedOnce) {
    this.setState({ clicked: clickedOnce });
    if (clickedOnce) {
      setTimeout(() => window.addEventListener('click', this.handleClick));
    }
    else {
      window.removeEventListener('click', this.handleClick);
    }
  }

  render() {
    const clickedOnce = this.state.clicked;
    const {
      children,
      color,
      confirmColor = 'bad',
      confirmContent = 'Confirm?',
      confirmIcon,
      ellipsis = true,
      icon,
      ...rest
    } = this.props;

    return (
      <Button
        icon={clickedOnce ? confirmIcon : icon}
        color={clickedOnce ? confirmColor : color}
        onClick={this.handleClick}
        {...rest}
      >
        {clickedOnce ? confirmContent : children}
      </Button>
    );
  }
}

Button.Confirm = ButtonConfirm;

type InputProps = Partial<{
  currentValue: string;
  defaultValue: string;
  fluid: boolean;
  maxLength: number;
  onCommit: (e: any, value: string) => void;
  placeholder: string;
}> &
  Props;

class ButtonInput extends Component<InputProps> {
  inputRef = createRef<HTMLInputElement>();
  inputting: boolean = false;

  constructor(props) {
    super(props);
  }

  setInInput(inInput: boolean) {
    const input = this.inputRef.current;
    if (!input) return;

    if (inInput) {
      input.value = this.props.currentValue || '';
      try {
        input.focus();
        input.select();
      } catch {}
    }
  }

  commitResult(e) {
    const input = this.inputRef.current;
    if (!input) return;

    const hasValue = input.value !== '';
    if (hasValue) {
      this.props.onCommit?.(e, input.value);
    } else {
      if (this.props.defaultValue) {
        this.props.onCommit?.(e, this.props.defaultValue);
      }
    }
  }

  render() {
    const {
      children,
      color = 'default',
      content,
      currentValue,
      defaultValue,
      disabled,
      fluid,
      icon,
      iconRotation,
      iconSpin,
      maxLength,
      placeholder,
      tooltip,
      tooltipPosition,
      ...rest
    } = this.props;

    const toDisplay = content || children;

    let buttonContent = (
      <Box
        className={classes([
          'Button',
          fluid && 'Button--fluid',
          'Button--color--' + color,
        ])}
        {...rest}
        onClick={() => this.setInInput(true)}
      >
        {icon && <Icon name={icon} rotation={iconRotation} spin={iconSpin} />}
        <div>{toDisplay}</div>
        <input
          disabled={!!disabled}
          ref={this.inputRef}
          className="NumberInput__input"
          style={{
            display: !this.inputting ? 'none' : '',
            textAlign: 'left',
          }}
          onBlur={(event) => {
            if (!this.inputting) {
              return;
            }
            this.setInInput(false);
            this.commitResult(event);
          }}
          onKeyDown={(event) => {
            if (event.key === KEY.Enter) {
              this.setInInput(false);
              this.commitResult(event);
              return;
            }
            if (isEscape(event.key)) {
              this.setInInput(false);
            }
          }}
        />
      </Box>
    );

    if (tooltip) {
      buttonContent = (
        <Tooltip content={tooltip} position={tooltipPosition as Placement}>
          {buttonContent}
        </Tooltip>
      );
    }

    return buttonContent;
  }
}

Button.Input = ButtonInput;

type FileProps = {
  accept: string;
  multiple?: boolean;
  onSelectFiles: (files: FileList) => void;
} & Props;

/**  Accepts file input */
class ButtonFile extends Component<FileProps, {clicked: boolean}> {
  inputRef = createRef<HTMLInputElement>();

  async handleChange(event: ChangeEvent<HTMLInputElement>) {
    const files = event.target.files;
    if (files?.length) {
      this.props.onSelectFiles(files);
      event.target.value = '';
    }
  }

  render() {
    const { accept, multiple, ...rest } = this.props;

    return (
      <>
        <Button onClick={() => this.inputRef.current?.click()} {...rest} />
        <input
          hidden
          type="file"
          ref={this.inputRef}
          accept={accept}
          multiple={multiple}
          onChange={this.handleChange}
        />
      </>
    );
  }
}

Button.File = ButtonFile;
