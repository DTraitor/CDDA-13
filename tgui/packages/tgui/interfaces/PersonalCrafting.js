import { Fragment } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Button, Dimmer, Icon, LabeledList, Section, Stack, Tabs, Input } from '../components';
import { Window } from '../layouts';

export const PersonalCrafting = (props, context) => {
  const { act, data } = useBackend(context);
  const { busy, display_craftable_only } = data;
  const crafting_recipes = data.crafting_recipes || {};
  // Sort everything into flat categories
  const categories = [];
  const recipes = [];
  for (let category of Object.keys(crafting_recipes)) {
    // Push category
    categories.push({
      name: category,
      category,
    });
    // Push recipes
    const _recipes = crafting_recipes[category];
    for (let recipe of _recipes) {
      recipes.push({
        ...recipe,
        category,
      });
    }
  }
  // Sort out the tab state
  const [tab, setTab] = useLocalState(context, 'tab', categories[0]?.name);
  const [searchQuery, setSearchQuery] = useLocalState(context, 'searchQuery');

  let shownRecipes = recipes.filter((recipe) => recipe.category === tab);
  if (searchQuery !== null) {
    shownRecipes = shownRecipes?.filter(
      (recipe, _) => recipe.name.search(searchQuery) >= 0);
  }
  return (
    <Window title="Crafting Menu" width={900} height={600}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              {categories.map((category) => (
                <Tabs.Tab
                  height={2}
                  key={category.name}
                  selected={category.name === tab}
                  onClick={() => {
                    setTab(category.name);
                    act('set_category', {
                      category: category.category,
                      subcategory: category.subcategory,
                    });
                  }}>
                  {category.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item>
                <Section fill title="Subcategories">
                  <Tabs vertical>
                    {categories.map((category) => (
                      <Tabs.Tab
                        height={2}
                        key={category.name}
                        selected={category.name === tab}
                        onClick={() => {
                          setTab(category.name);
                          act('set_category', {
                            category: category.category,
                          });
                        }}>
                        {category.name}
                      </Tabs.Tab>
                    ))}
                  </Tabs>
                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Section
                  fill
                  title="Recipes"
                  buttons={
                    <Fragment>
                      <Input
                        inline
                        placeholder="Search"
                        onInput={(e, value) => {
                          setSearchQuery(value);
                        }}
                      />
                      <Button.Checkbox
                        inline
                        content="Craftable Only"
                        checked={display_craftable_only}
                        onClick={() => act('toggle_recipes')}
                      />
                    </Fragment>
                  }>
                  <Section fill scrollable>
                    {busy ? (
                      <Dimmer fontSize="32px">
                        <Icon name="cog" spin={1} />
                        {' Crafting...'}
                      </Dimmer>
                    ) : (
                      <CraftingList craftables={shownRecipes} />
                    )}
                  </Section>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const CraftingList = (props, context) => {
  const { craftables = [] } = props;
  const { act, data } = useBackend(context);
  const { craftability = {}, display_craftable_only } = data;
  return craftables.map((craftable) => {
    if (display_craftable_only && !craftability[craftable.ref]) {
      return null;
    }
    return (
      <Section
        key={craftable.name}
        title={craftable.name}
        level={2}
        buttons={
          <Button
            icon="cog"
            content="Craft"
            disabled={!craftability[craftable.ref]}
            onClick={() =>
              act('make', {
                recipe: craftable.ref,
              })}
          />
        }>
        <LabeledList>
          {!!craftable.desc && (
            <LabeledList.Item label="Description">
              {craftable.desc}
            </LabeledList.Item>
          )}
          {!!craftable.req_text && (
            <LabeledList.Item label="Required">
              {craftable.req_text}
            </LabeledList.Item>
          )}
          {!!craftable.crafting_qualities_text && (
            <LabeledList.Item label="Crafting Qualities">
              {craftable.crafting_qualities_text}
            </LabeledList.Item>
          )}
          {!!craftable.machinery_text && (
            <LabeledList.Item label="Machinery">
              {craftable.machinery_text}
            </LabeledList.Item>
          )}
          {!!craftable.catalyst_text && (
            <LabeledList.Item label="Catalyst">
              {craftable.catalyst_text}
            </LabeledList.Item>
          )}
          {!!craftable.tool_text && (
            <LabeledList.Item label="Tools">
              {craftable.tool_text}
            </LabeledList.Item>
          )}
        </LabeledList>
      </Section>
    );
  });
};
