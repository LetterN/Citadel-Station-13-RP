/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { Component, InfernoNode } from 'inferno';

import { Box, BoxProps } from './Box';
import { Button } from './Button';

type Props = Partial<{
  buttons: InfernoNode;
  open: boolean;
  title: InfernoNode;
  icon: string;
}> &
  BoxProps;

export class Collapsible extends Component<Props, {open: boolean;}> {
  state = {
    open: false,
  };

  render() {
    const { children, color, title, buttons, icon, ...rest } = this.props;
    return (
      <Box mb={1}>
        <div className="Table">
          <div className="Table__cell">
            <Button
              fluid
              color={color}
              icon={icon ? icon : this.state.open ? 'chevron-down' : 'chevron-right'}
              onClick={() => { this.setState((prevState) => ({ open: !prevState.open })); }}
              {...rest}
            >
              {title}
            </Button>
          </div>
          {buttons && (
            <div className="Table__cell Table__cell--collapsing">{buttons}</div>
          )}
        </div>
        {this.state.open && <Box mt={1}>{children}</Box>}
      </Box>
    );
  }
}
