/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

// import { ReactNode, useState } from 'react';
import { InfernoNode } from 'inferno';
import { useLocalState } from '../backend';

import { Box, BoxProps } from './Box';
import { Button } from './Button';

type Props = Partial<{
  buttons: InfernoNode;
  open: boolean;
  title: InfernoNode;
  icon: string;
}> &
  BoxProps;

export function Collapsible(props: Props) {
  const { children, color, title, buttons, icon, ...rest } = props;
  // todo check if state gets reused when you have more than 1 collapsible
  const [open, setOpen] = useLocalState('collapsibleState', props.open);

  return (
    <Box mb={1}>
      <div className="Table">
        <div className="Table__cell">
          <Button
            fluid
            color={color}
            icon={icon ? icon : open ? 'chevron-down' : 'chevron-right'}
            onClick={() => setOpen(!open)}
            {...rest}
          >
            {title}
          </Button>
        </div>
        {buttons && (
          <div className="Table__cell Table__cell--collapsing">{buttons}</div>
        )}
      </div>
      {open && <Box mt={1}>{children}</Box>}
    </Box>
  );
}
